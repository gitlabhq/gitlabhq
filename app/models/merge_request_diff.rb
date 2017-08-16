class MergeRequestDiff < ActiveRecord::Base
  include Sortable
  include Importable
  include Gitlab::EncodingHelper

  # Prevent store of diff if commits amount more then 500
  COMMITS_SAFE_SIZE = 100

  # Valid types of serialized diffs allowed by Gitlab::Git::Diff
  VALID_CLASSES = [Hash, Rugged::Patch, Rugged::Diff::Delta].freeze

  belongs_to :merge_request
  has_many :merge_request_diff_files, -> { order(:merge_request_diff_id, :relative_order) }
  has_many :merge_request_diff_commits, -> { order(:merge_request_diff_id, :relative_order) }

  serialize :st_commits # rubocop:disable Cop/ActiveRecordSerialize
  serialize :st_diffs # rubocop:disable Cop/ActiveRecordSerialize

  state_machine :state, initial: :empty do
    state :collected
    state :overflow
    # Deprecated states: these are no longer used but these values may still occur
    # in the database.
    state :timeout
    state :overflow_commits_safe_size
    state :overflow_diff_files_limit
    state :overflow_diff_lines_limit
  end

  scope :viewable, -> { without_state(:empty) }

  # All diff information is collected from repository after object is created.
  # It allows you to override variables like head_commit_sha before getting diff.
  after_create :save_git_content, unless: :importing?

  def self.find_by_diff_refs(diff_refs)
    find_by(start_commit_sha: diff_refs.start_sha, head_commit_sha: diff_refs.head_sha, base_commit_sha: diff_refs.base_sha)
  end

  def self.select_without_diff
    select(column_names - ['st_diffs'])
  end

  def st_commits
    super || []
  end

  # Collect information about commits and diff from repository
  # and save it to the database as serialized data
  def save_git_content
    ensure_commit_shas
    save_commits
    save_diffs
    keep_around_commits
  end

  def ensure_commit_shas
    merge_request.fetch_ref
    self.start_commit_sha ||= merge_request.target_branch_sha
    self.head_commit_sha  ||= merge_request.source_branch_sha
    self.base_commit_sha  ||= find_base_sha
    save
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

  def raw_diffs(options = {})
    if options[:ignore_whitespace_change]
      @diffs_no_whitespace ||= compare.diffs(options)
    else
      @raw_diffs ||= {}
      @raw_diffs[options] ||= load_diffs(options)
    end
  end

  def commits
    @commits ||= load_commits
  end

  def last_commit_sha
    commit_shas.first
  end

  def first_commit
    commits.last
  end

  def base_commit
    return unless base_commit_sha

    project.commit(base_commit_sha)
  end

  def start_commit
    return unless start_commit_sha

    project.commit(start_commit_sha)
  end

  def head_commit
    return unless head_commit_sha

    project.commit(head_commit_sha)
  end

  def commit_shas
    if st_commits.present?
      st_commits.map { |commit| commit[:id] }
    else
      merge_request_diff_commits.map(&:sha)
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

  def diffs(diff_options = nil)
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
    self == merge_request.merge_request_diff
  end

  def compare_with(sha)
    # When compare merge request versions we want diff A..B instead of A...B
    # so we handle cases when user does squash and rebase of the commits between versions.
    # For this reason we set straight to true by default.
    CompareService.new(project, head_commit_sha).execute(project, sha, straight: true)
  end

  def commits_count
    if st_commits.present?
      st_commits.size
    else
      merge_request_diff_commits.size
    end
  end

  def utf8_st_diffs
    return [] if st_diffs.blank?

    st_diffs.map do |diff|
      diff.each do |k, v|
        diff[k] = encode_utf8(v) if v.respond_to?(:encoding)
      end
    end
  end

  private

  # Old GitLab implementations may have generated diffs as ["--broken-diff"].
  # Avoid an error 500 by ignoring bad elements. See:
  # https://gitlab.com/gitlab-org/gitlab-ce/issues/20776
  def valid_raw_diff?(raw)
    return false unless raw.respond_to?(:each)

    raw.any? { |element| VALID_CLASSES.include?(element.class) }
  end

  def create_merge_request_diff_files(diffs)
    rows = diffs.map.with_index do |diff, index|
      diff_hash = diff.to_hash.merge(
        binary: false,
        merge_request_diff_id: self.id,
        relative_order: index
      )

      # Compatibility with old diffs created with Psych.
      diff_hash.tap do |hash|
        diff_text = hash[:diff]

        if diff_text.encoding == Encoding::BINARY && !diff_text.ascii_only?
          hash[:binary] = true
          hash[:diff] = [diff_text].pack('m0')
        end
      end
    end

    Gitlab::Database.bulk_insert('merge_request_diff_files', rows)
  end

  def load_diffs(options)
    return Gitlab::Git::DiffCollection.new([]) unless diffs_from_database

    raw = diffs_from_database

    if paths = options[:paths]
      raw = raw.select do |diff|
        paths.include?(diff[:old_path]) || paths.include?(diff[:new_path])
      end
    end

    Gitlab::Git::DiffCollection.new(raw, options)
  end

  def diffs_from_database
    return @diffs_from_database if defined?(@diffs_from_database)

    @diffs_from_database =
      if st_diffs.present?
        if valid_raw_diff?(st_diffs)
          st_diffs
        end
      elsif merge_request_diff_files.present?
        merge_request_diff_files.map(&:to_hash)
      end
  end

  def load_commits
    commits = st_commits.presence || merge_request_diff_commits

    commits.map { |commit| Commit.from_hash(commit.to_hash, project) }
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

        create_merge_request_diff_files(diff_collection)
      end

      # Set our state to 'overflow' to make the #empty? and #collected?
      # methods (generated by StateMachine) return false.
      #
      # This attribution has to come at the end of the method so 'overflow'
      # state does not get overridden by 'collected'.
      new_attributes[:state] = :overflow if diff_collection.overflow?
    end

    update(new_attributes)
  end

  def save_commits
    MergeRequestDiffCommit.create_bulk(self.id, compare.commits.reverse)

    merge_request_diff_commits.reload
  end

  def repository
    project.repository
  end

  def find_base_sha
    return unless head_commit_sha && start_commit_sha

    project.merge_base_commit(head_commit_sha, start_commit_sha).try(:sha)
  end

  def keep_around_commits
    [repository, merge_request.source_project.repository].each do |repo|
      repo.keep_around(start_commit_sha)
      repo.keep_around(head_commit_sha)
      repo.keep_around(base_commit_sha)
    end
  end
end
