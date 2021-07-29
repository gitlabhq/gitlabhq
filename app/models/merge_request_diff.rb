# frozen_string_literal: true

class MergeRequestDiff < ApplicationRecord
  include Sortable
  include Importable
  include ManualInverseAssociation
  include EachBatch
  include Gitlab::Utils::StrongMemoize
  include ObjectStorage::BackgroundMove
  include BulkInsertableAssociations

  # Don't display more than 100 commits at once
  COMMITS_SAFE_SIZE = 100
  BATCH_SIZE = 1000

  # Applies to closed or merged MRs when determining whether to migrate their
  # diffs to external storage
  EXTERNAL_DIFF_CUTOFF = 7.days.freeze

  # The files_count column is a 2-byte signed integer. Look up the true value
  # from the database if this sentinel is seen
  FILES_COUNT_SENTINEL = 2**15 - 1

  belongs_to :merge_request

  manual_inverse_association :merge_request, :merge_request_diff

  has_many :merge_request_diff_files,
    -> { order(:merge_request_diff_id, :relative_order) },
    inverse_of: :merge_request_diff

  has_many :merge_request_diff_commits, -> { order(:merge_request_diff_id, :relative_order) }

  validates :base_commit_sha, :head_commit_sha, :start_commit_sha, sha: true
  validates :merge_request_id, uniqueness: { scope: :diff_type }, if: :merge_head?

  state_machine :state, initial: :empty do
    event :clean do
      transition any => :without_files
    end

    state :collected
    state :overflow
    # Diff files have been deleted by the system
    state :without_files
    # Deprecated states: these are no longer used but these values may still occur
    # in the database.
    state :timeout
    state :overflow_commits_safe_size
    state :overflow_diff_files_limit
    state :overflow_diff_lines_limit
  end

  enum diff_type: {
    regular: 1,
    merge_head: 2
  }

  scope :with_files, -> { without_states(:without_files, :empty) }
  scope :viewable, -> { without_state(:empty) }
  scope :by_commit_sha, ->(sha) do
    joins(:merge_request_diff_commits).where(merge_request_diff_commits: { sha: sha }).reorder(nil)
  end

  scope :by_project_id, -> (project_id) do
    joins(:merge_request).where(merge_requests: { target_project_id: project_id })
  end

  scope :recent, -> { order(id: :desc).limit(100) }

  scope :files_in_database, -> do
    where(stored_externally: [false, nil]).where(arel_table[:files_count].gt(0))
  end

  scope :not_latest_diffs, -> do
    merge_requests = MergeRequest.arel_table
    mr_diffs = arel_table

    join_condition = merge_requests[:id].eq(mr_diffs[:merge_request_id])
      .and(mr_diffs[:id].not_eq(merge_requests[:latest_merge_request_diff_id]))
      .and(mr_diffs[:diff_type].eq(diff_types[:regular]))

    arel_join = mr_diffs.join(merge_requests).on(join_condition)
    joins(arel_join.join_sources)
  end

  scope :old_merged_diffs, -> (before) do
    merge_requests = MergeRequest.arel_table
    mr_metrics = MergeRequest::Metrics.arel_table
    mr_diffs = arel_table

    mr_join = mr_diffs
      .join(merge_requests)
      .on(mr_diffs[:merge_request_id].eq(merge_requests[:id]))

    metrics_join_condition = mr_diffs[:merge_request_id]
      .eq(mr_metrics[:merge_request_id])
      .and(mr_metrics[:merged_at].not_eq(nil))

    metrics_join = mr_diffs.join(mr_metrics).on(metrics_join_condition)

    condition = MergeRequest.arel_table[:state_id].eq(MergeRequest.available_states[:merged])
      .and(MergeRequest::Metrics.arel_table[:merged_at].lteq(before))
      .and(MergeRequest::Metrics.arel_table[:merged_at].not_eq(nil))

    joins(metrics_join.join_sources, mr_join.join_sources).where(condition)
  end

  scope :old_closed_diffs, -> (before) do
    condition = MergeRequest.arel_table[:state_id].eq(MergeRequest.available_states[:closed])
      .and(MergeRequest::Metrics.arel_table[:latest_closed_at].lteq(before))

    joins(merge_request: :metrics).where(condition)
  end

  # This scope uses LATERAL JOIN to find the most recent MR diff association for the given merge requests.
  # To avoid joining the merge_requests table, we build an in memory table using the merge request ids.
  # Example:
  # SELECT ...
  # FROM (VALUES (MR_ID_1),(MR_ID_2)) merge_requests (id)
  # INNER JOIN LATERAL (...)
  scope :latest_diff_for_merge_requests, -> (merge_requests) do
    mrs = Array(merge_requests)
    return MergeRequestDiff.none if mrs.empty?

    merge_request_table = MergeRequest.arel_table
    merge_request_diff_table = MergeRequestDiff.arel_table

    join_query = MergeRequestDiff
      .where(merge_request_table[:id].eq(merge_request_diff_table[:merge_request_id]))
      .order(created_at: :desc)
      .limit(1)

    mr_id_list = mrs.map { |mr| "(#{Integer(mr.id)})" }.join(",")

    MergeRequestDiff
      .from("(VALUES #{mr_id_list}) merge_requests (id)")
      .joins("INNER JOIN LATERAL (#{join_query.to_sql}) #{MergeRequestDiff.table_name} ON TRUE")
      .includes(:merge_request_diff_commits)
  end

  class << self
    def ids_for_external_storage_migration(limit:)
      return [] unless Gitlab.config.external_diffs.enabled

      case Gitlab.config.external_diffs.when
      when 'always'
        ids_for_external_storage_migration_strategy_always(limit: limit)
      when 'outdated'
        ids_for_external_storage_migration_strategy_outdated(limit: limit)
      else
        []
      end
    end

    def ids_for_external_storage_migration_strategy_always(limit:)
      files_in_database.limit(limit).pluck(:id)
    end

    def ids_for_external_storage_migration_strategy_outdated(limit:)
      # Outdated is too complex to be a single SQL query, so split into three
      before = EXTERNAL_DIFF_CUTOFF.ago

      ids = files_in_database
        .old_merged_diffs(before)
        .limit(limit)
        .pluck(:id)

      return ids if ids.size >= limit

      ids += files_in_database
        .old_closed_diffs(before)
        .limit(limit - ids.size)
        .pluck(:id)

      return ids if ids.size >= limit

      ids + files_in_database
        .not_latest_diffs
        .limit(limit - ids.size)
        .pluck(:id)
    end
  end

  mount_uploader :external_diff, ExternalDiffUploader

  # All diff information is collected from repository after object is created.
  # It allows you to override variables like head_commit_sha before getting diff.
  after_create :save_git_content, unless: :importing?
  after_create_commit :set_as_latest_diff, unless: :importing?

  after_save :update_external_diff_store
  after_save :set_count_columns

  def self.find_by_diff_refs(diff_refs)
    find_by(start_commit_sha: diff_refs.start_sha, head_commit_sha: diff_refs.head_sha, base_commit_sha: diff_refs.base_sha)
  end

  def viewable?
    collected? || without_files? || overflow?
  end

  # Collect information about commits and diff from repository
  # and save it to the database as serialized data
  def save_git_content
    ensure_commit_shas
    save_commits
    save_diffs

    # Another set of `after_save` hooks will be called here when we update the record
    save
    # We need to reset so that dirty tracking is reset when running the original set
    # of `after_save` hooks that come after this `after_create` hook. Otherwise, the
    # hooks that run when an attribute was changed are run twice.
    reset

    keep_around_commits unless importing?
  end

  def set_as_latest_diff
    # Don't set merge_head diff as latest so it won't get considered as the
    # MergeRequest#merge_request_diff.
    return if merge_head?

    MergeRequest
      .where('id = ? AND COALESCE(latest_merge_request_diff_id, 0) < ?', self.merge_request_id, self.id)
      .update_all(latest_merge_request_diff_id: self.id)
  end

  def ensure_commit_shas
    self.start_commit_sha ||= merge_request.target_branch_sha

    if merge_head? && merge_request.merge_ref_head.present?
      diff_refs = merge_request.merge_ref_head.diff_refs

      self.head_commit_sha  ||= diff_refs.head_sha
      self.base_commit_sha  ||= diff_refs.base_sha
    else
      self.head_commit_sha  ||= merge_request.source_branch_sha
      self.base_commit_sha  ||= find_base_sha
    end
  end

  # Override head_commit_sha to keep compatibility with merge request diff
  # created before version 8.4 that does not store head_commit_sha in separate db field.
  def head_commit_sha
    if persisted? && super.nil?
      last_commit_sha
    else
      super
    end
  end

  def files_count
    db_value = read_attribute(:files_count)

    case db_value
    when nil, FILES_COUNT_SENTINEL
      merge_request_diff_files.count
    else
      db_value
    end
  end

  # This method will rely on repository branch sha
  # in case start_commit_sha is nil. Its necesarry for old merge request diff
  # created before version 8.4 to work
  def safe_start_commit_sha
    start_commit_sha || merge_request.target_branch_sha
  end

  def size
    real_size.presence || raw_diffs.size
  end

  def lines_count
    strong_memoize(:lines_count) do
      raw_diffs(limits: false).line_count
    end
  end

  def raw_diffs(options = {})
    if options[:ignore_whitespace_change]
      @diffs_no_whitespace ||= compare.diffs(options)
    else
      @raw_diffs ||= {}
      @raw_diffs[options] ||= load_diffs(options)
    end
  end

  def commits(limit: nil)
    strong_memoize(:"commits_#{limit || 'all'}") do
      load_commits(limit: limit)
    end
  end

  def last_commit_sha
    commit_shas(limit: 1).first
  end

  def first_commit
    commits.last
  end

  def last_commit
    commits.first
  end

  def base_commit
    return unless base_commit_sha

    project.commit_by(oid: base_commit_sha)
  end

  def start_commit
    return unless start_commit_sha

    project.commit_by(oid: start_commit_sha)
  end

  def head_commit
    return unless head_commit_sha

    project.commit_by(oid: head_commit_sha)
  end

  def commit_shas(limit: nil)
    if association(:merge_request_diff_commits).loaded?
      sorted_diff_commits = merge_request_diff_commits.sort_by { |diff_commit| [diff_commit.id, diff_commit.relative_order] }
      sorted_diff_commits = sorted_diff_commits.take(limit) if limit
      sorted_diff_commits.map(&:sha)
    else
      merge_request_diff_commits.limit(limit).pluck(:sha)
    end
  end

  def includes_any_commits?(shas)
    return false if shas.blank?

    # when the number of shas is huge (1000+) we don't want
    # to pass them all as an SQL param, let's pass them in batches
    shas.each_slice(BATCH_SIZE).any? do |batched_shas|
      merge_request_diff_commits.where(sha: batched_shas).exists?
    end
  end

  def diff_refs=(new_diff_refs)
    self.base_commit_sha = new_diff_refs&.base_sha
    self.start_commit_sha = new_diff_refs&.start_sha
    self.head_commit_sha = new_diff_refs&.head_sha
  end

  def diff_refs
    return unless start_commit_sha || base_commit_sha

    Gitlab::Diff::DiffRefs.new(
      base_sha:  base_commit_sha,
      start_sha: start_commit_sha,
      head_sha:  head_commit_sha
    )
  end

  # MRs created before 8.4 don't store their true diff refs (start and base),
  # but we need to get a commit SHA for the "View file @ ..." link by a file,
  # so we use an approximation of the diff refs if we can't get the actual one.
  #
  # These will not be the actual diff refs if the target branch was merged into
  # the source branch after the merge request was created, but it is good enough
  # for the specific purpose of linking to a commit.
  #
  # It is not good enough for highlighting diffs, so we can't simply pass
  # these as `diff_refs.`
  def fallback_diff_refs
    real_refs = diff_refs
    return real_refs if real_refs

    likely_base_commit_sha = (first_commit&.parent || first_commit)&.sha

    Gitlab::Diff::DiffRefs.new(
      base_sha:  likely_base_commit_sha,
      start_sha: safe_start_commit_sha,
      head_sha:  head_commit_sha
    )
  end

  def diff_refs_by_sha?
    base_commit_sha? && head_commit_sha? && start_commit_sha?
  end

  def diffs_in_batch(batch_page, batch_size, diff_options:)
    fetching_repository_diffs(diff_options) do |comparison|
      reorder_diff_files!
      diffs_batch = diffs_in_batch_collection(batch_page, batch_size, diff_options: diff_options)

      if comparison
        if diff_options[:paths].blank? && !without_files?
          # Return the empty MergeRequestDiffBatch for an out of bound batch request
          break diffs_batch if diffs_batch.diff_file_paths.blank?

          diff_options.merge!(
            paths: diffs_batch.diff_file_paths,
            pagination_data: diffs_batch.pagination_data
          )
        end

        comparison.diffs(diff_options)
      else
        diffs_batch
      end
    end
  end

  def diffs(diff_options = nil)
    fetching_repository_diffs(diff_options) do |comparison|
      # It should fetch the repository when diffs are cleaned by the system.
      # We don't keep these for storage overload purposes.
      # See https://gitlab.com/gitlab-org/gitlab-foss/issues/37639
      if comparison
        comparison.diffs(diff_options)
      else
        reorder_diff_files!
        diffs_collection(diff_options)
      end
    end
  end

  # Should always return the DB persisted diffs collection
  # (e.g. Gitlab::Diff::FileCollection::MergeRequestDiff.
  # It's useful when trying to invalidate old caches through
  # FileCollection::MergeRequestDiff#clear_cache!
  def diffs_collection(diff_options = nil)
    Gitlab::Diff::FileCollection::MergeRequestDiff.new(self, diff_options: diff_options)
  end

  def project
    merge_request.target_project
  end

  def compare
    @compare ||=
      Gitlab::Git::Compare.new(
        repository.raw_repository,
        safe_start_commit_sha,
        head_commit_sha
      )
  end

  def latest?
    self.id == merge_request.latest_merge_request_diff_id
  end

  # rubocop: disable CodeReuse/ServiceClass
  def compare_with(sha)
    # When compare merge request versions we want diff A..B instead of A...B
    # so we handle cases when user does squash and rebase of the commits between versions.
    # For this reason we set straight to true by default.
    CompareService.new(project, head_commit_sha).execute(project, sha, straight: true)
  end
  # rubocop: enable CodeReuse/ServiceClass

  def modified_paths(fallback_on_overflow: false)
    if fallback_on_overflow && overflow?
      # This is an extremely slow means to find the modified paths for a given
      #   MergeRequestDiff. This should be avoided, except where the limit of
      #   1_000 (as of %12.10) entries returned by the default behavior is an
      #   issue.
      strong_memoize(:overflowed_modified_paths) do
        project.repository.diff_stats(
          base_commit_sha,
          head_commit_sha
        ).paths
      end
    else
      strong_memoize(:modified_paths) do
        merge_request_diff_files.pluck(:new_path, :old_path).flatten.uniq
      end
    end
  end

  def update_external_diff_store
    return unless saved_change_to_external_diff? || saved_change_to_stored_externally?

    update_column(:external_diff_store, external_diff.object_store)
  end

  # If enabled, yields the external file containing the diff. Otherwise, yields
  # nil. This method is not thread-safe, but it *is* re-entrant, which allows
  # multiple merge_request_diff_files to load their data efficiently
  def opening_external_diff
    return yield(nil) unless stored_externally?
    return yield(@external_diff_file) if @external_diff_file

    external_diff.open do |file|
      @external_diff_file = file

      yield(@external_diff_file)
    ensure
      @external_diff_file = nil
    end
  end

  # Transactionally migrate the current merge_request_diff_files entries to
  # external storage. If external storage isn't an option for this diff, the
  # method is a no-op.
  def migrate_files_to_external_storage!
    return if stored_externally? || !use_external_diff? || files_count == 0

    rows = build_merge_request_diff_files(merge_request_diff_files)
    rows = build_external_merge_request_diff_files(rows)

    # Perform carrierwave activity before entering the database transaction.
    # This is safe as until the `external_diff_store` column is changed, we will
    # continue to consult the in-database content.
    self.external_diff.store!

    transaction do
      MergeRequestDiffFile.where(merge_request_diff_id: id).delete_all
      Gitlab::Database.main.bulk_insert('merge_request_diff_files', rows) # rubocop:disable Gitlab/BulkInsert
      save!
    end

    merge_request_diff_files.reset
  end

  # Transactionally migrate the current merge_request_diff_files entries from
  # external storage, back to the database. This is the rollback operation for
  # +migrate_files_to_external_storage!+
  #
  # If this diff isn't in external storage, the method is a no-op.
  def migrate_files_to_database!
    return unless stored_externally?
    return if files_count == 0

    rows = convert_external_diffs_to_database

    transaction do
      MergeRequestDiffFile.where(merge_request_diff_id: id).delete_all
      Gitlab::Database.main.bulk_insert('merge_request_diff_files', rows) # rubocop:disable Gitlab/BulkInsert
      update!(stored_externally: false)
    end

    # Only delete the external diff file after the contents have been saved to
    # the database
    remove_external_diff!
    merge_request_diff_files.reset
  end

  private

  def convert_external_diffs_to_database
    opening_external_diff do |external_file|
      merge_request_diff_files.map do |diff_file|
        row = diff_file.attributes.except('diff')

        raise "Diff file lacks external diff offset or size: #{row.inspect}" unless
          row['external_diff_offset'] && row['external_diff_size']

        # The diff in the external file is already base64-encoded if necessary,
        # matching the 'binary' attribute of the row. Reading it directly allows
        # a cycle of decode-encode to be skipped
        external_file.seek(row.delete('external_diff_offset'))
        row['diff'] = external_file.read(row.delete('external_diff_size'))

        row
      end
    end
  end

  def diffs_in_batch_collection(batch_page, batch_size, diff_options:)
    Gitlab::Diff::FileCollection::MergeRequestDiffBatch.new(self,
                                                            batch_page,
                                                            batch_size,
                                                            diff_options: diff_options)
  end

  def encode_in_base64?(diff_text)
    return false if diff_text.nil?

    (diff_text.encoding == Encoding::BINARY && !diff_text.ascii_only?) ||
      diff_text.include?("\0")
  end

  def build_external_merge_request_diff_files(rows)
    tempfile = build_external_diff_tempfile(rows)

    self.external_diff = tempfile
    self.stored_externally = true

    rows
  ensure
    tempfile&.unlink
  end

  def create_merge_request_diff_files(rows)
    rows = build_external_merge_request_diff_files(rows) if use_external_diff?

    # Faster inserts
    Gitlab::Database.main.bulk_insert('merge_request_diff_files', rows) # rubocop:disable Gitlab/BulkInsert
  end

  def build_external_diff_tempfile(rows)
    Tempfile.open(external_diff.filename) do |file|
      rows.each do |row|
        data = row.delete(:diff)
        row[:external_diff_offset] = file.pos
        row[:external_diff_size] = data&.bytesize || 0

        file.write(data)
      end

      file
    end
  end

  def build_merge_request_diff_files(diffs)
    sort_diffs(diffs).map.with_index do |diff, index|
      diff_hash = diff.to_hash.merge(
        binary: false,
        merge_request_diff_id: self.id,
        relative_order: index
      )

      # Compatibility with old diffs created with Psych.
      diff_hash.tap do |hash|
        diff_text = hash[:diff]

        if encode_in_base64?(diff_text)
          hash[:binary] = true
          hash[:diff] = [diff_text].pack('m0')
        end
      end
    end
  end

  # Yields the block with the repository Compare object if it should
  # fetch diffs from the repository instead DB.
  def fetching_repository_diffs(diff_options)
    return unless block_given?

    diff_options ||= {}

    # Can be read as: fetch the persisted diffs if yielded without the
    # Compare object.
    return yield unless without_files? || diff_options[:ignore_whitespace_change]
    return yield unless diff_refs&.complete?

    comparison = diff_refs.compare_in(repository.project)

    return yield unless comparison

    yield(comparison)
  end

  def use_external_diff?
    return false unless Gitlab.config.external_diffs.enabled

    case Gitlab.config.external_diffs.when
    when 'always'
      true
    when 'outdated'
      outdated_by_merge? || outdated_by_closure? || old_version?
    else
      false # Disable external diffs if misconfigured
    end
  end

  def outdated_by_merge?
    return false unless merge_request&.metrics&.merged_at

    merge_request.merged? && merge_request.metrics.merged_at < EXTERNAL_DIFF_CUTOFF.ago
  end

  def outdated_by_closure?
    return false unless merge_request&.metrics&.latest_closed_at

    merge_request.closed? && merge_request.metrics.latest_closed_at < EXTERNAL_DIFF_CUTOFF.ago
  end

  def old_version?
    latest_id = MergeRequest
      .where(id: merge_request_id)
      .limit(1)
      .pluck(:latest_merge_request_diff_id)
      .first

    latest_id && self.id < latest_id
  end

  def load_diffs(options)
    # Ensure all diff files operate on the same external diff file instance if
    # present. This reduces file open/close overhead.
    opening_external_diff do
      collection = merge_request_diff_files

      if paths = options[:paths]
        collection = collection.where('old_path IN (?) OR new_path IN (?)', paths, paths)
      end

      Gitlab::Git::DiffCollection.new(collection.map(&:to_hash), options)
    end
  end

  def load_commits(limit: nil)
    commits = merge_request_diff_commits.with_users.limit(limit)
      .map { |commit| Commit.from_hash(commit.to_hash, project) }

    CommitCollection
      .new(merge_request.source_project, commits, merge_request.source_branch)
  end

  def save_diffs
    new_attributes = {}

    if compare.commits.empty?
      new_attributes[:state] = :empty
    else
      diff_collection = compare.diffs(Commit.max_diff_options(project: merge_request.project))
      new_attributes[:real_size] = diff_collection.real_size

      if diff_collection.any?
        new_attributes[:state] = :collected

        rows = build_merge_request_diff_files(diff_collection)
        create_merge_request_diff_files(rows)
        new_attributes[:sorted] = true
        self.class.uncached { merge_request_diff_files.reset }
      end

      # Set our state to 'overflow' to make the #empty? and #collected?
      # methods (generated by StateMachine) return false.
      #
      # This attribution has to come at the end of the method so 'overflow'
      # state does not get overridden by 'collected'.
      new_attributes[:state] = :overflow if diff_collection.overflow?
    end

    assign_attributes(new_attributes)
  end

  def save_commits
    MergeRequestDiffCommit.create_bulk(self.id, compare.commits.reverse)
    self.class.uncached { merge_request_diff_commits.reset }
  end

  def set_count_columns
    update_columns(
      commits_count: merge_request_diff_commits.size,
      files_count: [FILES_COUNT_SENTINEL, merge_request_diff_files.size].min
    )
  end

  def repository
    project.repository
  end

  def find_base_sha
    return unless head_commit_sha && start_commit_sha

    project.merge_base_commit(head_commit_sha, start_commit_sha).try(:sha)
  end

  def keep_around_commits
    [repository, merge_request.source_project.repository].uniq.each do |repo|
      repo.keep_around(start_commit_sha, head_commit_sha, base_commit_sha)
    end
  end

  def reorder_diff_files!
    return if sorted? || merge_request_diff_files.empty?

    diff_files = sort_diffs(merge_request_diff_files)

    diff_files.each_with_index do |diff_file, index|
      diff_file.relative_order = index
    end

    transaction do
      # The `merge_request_diff_files` table doesn't have an `id` column so
      # we cannot use `Gitlab::Database::BulkUpdate`.
      MergeRequestDiffFile.where(merge_request_diff_id: id).delete_all
      MergeRequestDiffFile.bulk_insert!(diff_files)
      update_column(:sorted, true)
    end
  end

  def sort_diffs(diffs)
    Gitlab::Diff::FileCollectionSorter.new(diffs).sort
  end
end

MergeRequestDiff.prepend_mod_with('MergeRequestDiff')
