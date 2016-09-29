class MergeRequestDiff < ActiveRecord::Base
  include Sortable
  include Importable
  include EncodingHelper

  # Prevent store of diff if commits amount more then 500
  COMMITS_SAFE_SIZE = 100

  # Valid types of serialized diffs allowed by Gitlab::Git::Diff
  VALID_CLASSES = [Hash, Rugged::Patch, Rugged::Diff::Delta]

  belongs_to :merge_request

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

  serialize :st_commits
  serialize :st_diffs

  # All diff information is collected from repository after object is created.
  # It allows you to override variables like head_commit_sha before getting diff.
  after_create :save_git_content, unless: :importing?

  def self.select_without_diff
    select(column_names - ['st_diffs'])
  end

  def st_commits
    super || []
  end

  # Collect information about commits and diff from repository
  # and save it to the database as serialized data
  def save_git_content
    ensure_commits_sha
    save_commits
    reload_commits
    save_diffs
    keep_around_commits
  end

  def ensure_commits_sha
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
      last_commit.try(:sha)
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
      @diffs_no_whitespace ||=
        Gitlab::Git::Compare.new(
          repository.raw_repository,
          safe_start_commit_sha,
          head_commit_sha).diffs(options)
    else
      @raw_diffs ||= {}
      @raw_diffs[options] ||= load_diffs(st_diffs, options)
    end
  end

  def commits
    @commits ||= load_commits(st_commits)
  end

  def reload_commits
    @commits = nil
    commits
  end

  def last_commit
    commits.first
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

  def commits_sha
    if @commits
      commits.map(&:sha)
    else
      st_commits.map { |commit| commit[:id] }
    end
  end

  def diff_refs
    return unless start_commit_sha || base_commit_sha

    Gitlab::Diff::DiffRefs.new(
      base_sha:  base_commit_sha,
      start_sha: start_commit_sha,
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

  def compare_with(sha, straight = true)
    # When compare merge request versions we want diff A..B instead of A...B
    # so we handle cases when user squash and rebase commits in one of versions.
    # For this reason we set straight to true by default.
    CompareService.new.execute(project, head_commit_sha, project, sha, straight)
  end

  private

  # Old GitLab implementations may have generated diffs as ["--broken-diff"].
  # Avoid an error 500 by ignoring bad elements. See:
  # https://gitlab.com/gitlab-org/gitlab-ce/issues/20776
  def valid_raw_diff?(raw)
    return false unless raw.respond_to?(:each)

    raw.any? { |element| VALID_CLASSES.include?(element.class) }
  end

  def dump_commits(commits)
    commits.map(&:to_hash)
  end

  def load_commits(array)
    array.map { |hash| Commit.new(Gitlab::Git::Commit.new(hash), merge_request.source_project) }
  end

  # Load all commits related to current merge request diff from repo
  # and save it as array of hashes in st_commits db field
  def save_commits
    new_attributes = {}

    commits = compare.commits

    if commits.present?
      commits = Commit.decorate(commits, merge_request.source_project).reverse
      new_attributes[:st_commits] = dump_commits(commits)
    end

    update_columns_serialized(new_attributes)
  end

  def dump_diffs(diffs)
    if diffs.respond_to?(:map)
      diffs.map(&:to_hash)
    end
  end

  def load_diffs(raw, options)
    if valid_raw_diff?(raw)
      if paths = options[:paths]
        raw = raw.select do |diff|
          paths.include?(diff[:old_path]) || paths.include?(diff[:new_path])
        end
      end

      Gitlab::Git::DiffCollection.new(raw, options)
    else
      Gitlab::Git::DiffCollection.new([])
    end
  end

  # Load diffs between branches related to current merge request diff from repo
  # and save it as array of hashes in st_diffs db field
  def save_diffs
    new_attributes = {}
    new_diffs = []

    if commits.size.zero?
      new_attributes[:state] = :empty
    else
      diff_collection = compare.diffs(Commit.max_diff_options)

      if diff_collection.overflow?
        # Set our state to 'overflow' to make the #empty? and #collected?
        # methods (generated by StateMachine) return false.
        new_attributes[:state] = :overflow
      end

      new_attributes[:real_size] = diff_collection.real_size

      if diff_collection.any?
        new_diffs = dump_diffs(diff_collection)
        new_attributes[:state] = :collected
      end
    end

    new_attributes[:st_diffs] = new_diffs
    update_columns_serialized(new_attributes)
  end

  def repository
    project.repository
  end

  def find_base_sha
    return unless head_commit_sha && start_commit_sha

    project.merge_base_commit(head_commit_sha, start_commit_sha).try(:sha)
  end

  def utf8_st_diffs
    st_diffs.map do |diff|
      diff.each do |k, v|
        diff[k] = encode_utf8(v) if v.respond_to?(:encoding)
      end
    end
  end

  #
  # #save or #update_attributes providing changes on serialized attributes do a lot of
  # serialization and deserialization calls resulting in bad performance.
  # Using #update_columns solves the problem with just one YAML.dump per serialized attribute that we provide.
  # As a tradeoff we need to reload the current instance to properly manage time objects on those serialized
  # attributes. So to keep the same behaviour as the attribute assignment we reload the instance.
  # The difference is in the usage of
  # #write_attribute= (#update_attributes) and #raw_write_attribute= (#update_columns)
  #
  # Ex:
  #
  #   new_attributes[:st_commits].first.slice(:committed_date)
  #   => {:committed_date=>2014-02-27 11:01:38 +0200}
  #   YAML.load(YAML.dump(new_attributes[:st_commits].first.slice(:committed_date)))
  #   => {:committed_date=>2014-02-27 10:01:38 +0100}
  #
  def update_columns_serialized(new_attributes)
    return unless new_attributes.any?

    update_columns(new_attributes.merge(updated_at: current_time_from_proper_timezone))
    reload
  end

  def keep_around_commits
    repository.keep_around(start_commit_sha)
    repository.keep_around(head_commit_sha)
    repository.keep_around(base_commit_sha)
  end
end
