# frozen_string_literal: true

class MergeRequestDiff < ApplicationRecord
  include Sortable
  include Importable
  include ManualInverseAssociation
  include EachBatch
  include Gitlab::Utils::StrongMemoize
  include ObjectStorage::BackgroundMove

  # Don't display more than 100 commits at once
  COMMITS_SAFE_SIZE = 100
  BATCH_SIZE = 1000

  # Applies to closed or merged MRs when determining whether to migrate their
  # diffs to external storage
  EXTERNAL_DIFF_CUTOFF = 7.days.freeze

  belongs_to :merge_request

  manual_inverse_association :merge_request, :merge_request_diff

  has_many :merge_request_diff_files,
    -> { order(:merge_request_diff_id, :relative_order) },
    inverse_of: :merge_request_diff

  has_many :merge_request_diff_commits, -> { order(:merge_request_diff_id, :relative_order) }

  validates :base_commit_sha, :head_commit_sha, :start_commit_sha, sha: true

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

  scope :with_files, -> { without_states(:without_files, :empty) }
  scope :viewable, -> { without_state(:empty) }
  scope :by_commit_sha, ->(sha) do
    joins(:merge_request_diff_commits).where(merge_request_diff_commits: { sha: sha }).reorder(nil)
  end
  scope :has_diff_files, -> { where(id: MergeRequestDiffFile.select(:merge_request_diff_id)) }

  scope :by_project_id, -> (project_id) do
    joins(:merge_request).where(merge_requests: { target_project_id: project_id })
  end

  scope :recent, -> { order(id: :desc).limit(100) }
  scope :files_in_database, -> { has_diff_files.where(stored_externally: [false, nil]) }

  scope :not_latest_diffs, -> do
    merge_requests = MergeRequest.arel_table
    mr_diffs = arel_table

    join_condition = merge_requests[:id].eq(mr_diffs[:merge_request_id])
      .and(mr_diffs[:id].not_eq(merge_requests[:latest_merge_request_diff_id]))

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

  def self.ids_for_external_storage_migration(limit:)
    # No point doing any work unless the feature is enabled
    return [] unless Gitlab.config.external_diffs.enabled

    case Gitlab.config.external_diffs.when
    when 'always'
      files_in_database.limit(limit).pluck(:id)
    when 'outdated'
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
    else
      []
    end
  end

  mount_uploader :external_diff, ExternalDiffUploader

  # All diff information is collected from repository after object is created.
  # It allows you to override variables like head_commit_sha before getting diff.
  after_create :save_git_content, unless: :importing?
  after_create_commit :set_as_latest_diff

  after_save :update_external_diff_store, if: -> { !importing? && saved_change_to_external_diff? }

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
    MergeRequest
      .where('id = ? AND COALESCE(latest_merge_request_diff_id, 0) < ?', self.merge_request_id, self.id)
      .update_all(latest_merge_request_diff_id: self.id)
  end

  def ensure_commit_shas
    self.start_commit_sha ||= merge_request.target_branch_sha
    self.head_commit_sha  ||= merge_request.source_branch_sha
    self.base_commit_sha  ||= find_base_sha
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
    merge_request_diff_commits.limit(limit).pluck(:sha)
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
    Gitlab::Diff::FileCollection::MergeRequestDiffBatch.new(self,
                                                            batch_page,
                                                            batch_size,
                                                            diff_options: diff_options)
  end

  def diffs(diff_options = nil)
    if without_files? && comparison = diff_refs&.compare_in(project)
      # It should fetch the repository when diffs are cleaned by the system.
      # We don't keep these for storage overload purposes.
      # See https://gitlab.com/gitlab-org/gitlab-foss/issues/37639
      comparison.diffs(diff_options)
    else
      diffs_collection(diff_options)
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

  def modified_paths
    strong_memoize(:modified_paths) do
      merge_request_diff_files.pluck(:new_path, :old_path).flatten.uniq
    end
  end

  # Carrierwave defines `write_uploader` dynamically on this class, so `super`
  # does not work. Alias the carrierwave method so we can call it when needed
  alias_method :carrierwave_write_uploader, :write_uploader

  # The `external_diff`, `external_diff_store`, and `stored_externally`
  # columns were introduced in GitLab 11.8, but some background migration specs
  # use factories that rely on current code with an old schema. Without these
  # `has_attribute?` guards, they fail with a `MissingAttributeError`.
  #
  # For more details, see: https://gitlab.com/gitlab-org/gitlab-foss/issues/44990

  def write_uploader(column, identifier)
    carrierwave_write_uploader(column, identifier) if has_attribute?(column)
  end

  def update_external_diff_store
    update_column(:external_diff_store, external_diff.object_store) if
      has_attribute?(:external_diff_store)
  end

  def saved_change_to_external_diff?
    super if has_attribute?(:external_diff)
  end

  def stored_externally
    super if has_attribute?(:stored_externally)
  end
  alias_method :stored_externally?, :stored_externally

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
    return if stored_externally? || !use_external_diff? || merge_request_diff_files.count == 0

    rows = build_merge_request_diff_files(merge_request_diff_files)

    transaction do
      MergeRequestDiffFile.where(merge_request_diff_id: id).delete_all
      create_merge_request_diff_files(rows)
      save!
    end

    merge_request_diff_files.reset
  end

  private

  def encode_in_base64?(diff_text)
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
    Gitlab::Database.bulk_insert('merge_request_diff_files', rows)
  end

  def build_external_diff_tempfile(rows)
    Tempfile.open(external_diff.filename) do |file|
      rows.each do |row|
        data = row.delete(:diff)
        row[:external_diff_offset] = file.pos
        row[:external_diff_size] = data.bytesize

        file.write(data)
      end

      file
    end
  end

  def build_merge_request_diff_files(diffs)
    diffs.map.with_index do |diff, index|
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

  def use_external_diff?
    return false unless has_attribute?(:external_diff)
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
    commits = merge_request_diff_commits.limit(limit)
      .map { |commit| Commit.from_hash(commit.to_hash, project) }

    CommitCollection
      .new(merge_request.source_project, commits, merge_request.source_branch)
  end

  def save_diffs
    new_attributes = {}

    if compare.commits.size.zero?
      new_attributes[:state] = :empty
    else
      diff_collection = compare.diffs(Commit.max_diff_options)
      new_attributes[:real_size] = diff_collection.real_size

      if diff_collection.any?
        new_attributes[:state] = :collected

        rows = build_merge_request_diff_files(diff_collection)
        create_merge_request_diff_files(rows)
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

    # merge_request_diff_commits.reset is preferred way to reload associated
    # objects but it returns cached result for some reason in this case
    # we can circumvent that by specifying that we need an uncached reload
    commits = self.class.uncached { merge_request_diff_commits.reset }
    self.commits_count = commits.size
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
end

MergeRequestDiff.prepend_if_ee('EE::MergeRequestDiff')
