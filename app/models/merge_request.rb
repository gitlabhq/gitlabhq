class MergeRequest < ActiveRecord::Base
  include InternalId
  include Issuable
  include Referable
  include Sortable
  include Importable

  belongs_to :target_project, class_name: "Project"
  belongs_to :source_project, class_name: "Project"
  belongs_to :merge_user, class_name: "User"

  has_many :merge_request_diffs, dependent: :destroy
  has_one :merge_request_diff,
    -> { order('merge_request_diffs.id DESC') }

  has_many :events, as: :target, dependent: :destroy

  has_many :merge_requests_closing_issues, class_name: 'MergeRequestsClosingIssues', dependent: :delete_all

  serialize :merge_params, Hash

  after_create :ensure_merge_request_diff, unless: :importing?
  after_update :reload_diff_if_branch_changed

  delegate :commits, :real_size, to: :merge_request_diff, prefix: nil

  # When this attribute is true some MR validation is ignored
  # It allows us to close or modify broken merge requests
  attr_accessor :allow_broken

  # Temporary fields to store compare vars
  # when creating new merge request
  attr_accessor :can_be_created, :compare_commits, :diff_options, :compare

  state_machine :state, initial: :opened do
    event :close do
      transition [:reopened, :opened] => :closed
    end

    event :mark_as_merged do
      transition [:reopened, :opened, :locked] => :merged
    end

    event :reopen do
      transition closed: :reopened
    end

    event :lock_mr do
      transition [:reopened, :opened] => :locked
    end

    event :unlock_mr do
      transition locked: :reopened
    end

    after_transition any => :locked do |merge_request, transition|
      merge_request.locked_at = Time.now
      merge_request.save
    end

    after_transition locked: (any - :locked) do |merge_request, transition|
      merge_request.locked_at = nil
      merge_request.save
    end

    state :opened
    state :reopened
    state :closed
    state :merged
    state :locked
  end

  state_machine :merge_status, initial: :unchecked do
    event :mark_as_unchecked do
      transition [:can_be_merged, :cannot_be_merged] => :unchecked
    end

    event :mark_as_mergeable do
      transition [:unchecked, :cannot_be_merged] => :can_be_merged
    end

    event :mark_as_unmergeable do
      transition [:unchecked, :can_be_merged] => :cannot_be_merged
    end

    state :unchecked
    state :can_be_merged
    state :cannot_be_merged

    around_transition do |merge_request, transition, block|
      Gitlab::Timeless.timeless(merge_request, &block)
    end
  end

  validates :source_project, presence: true, unless: [:allow_broken, :importing?, :closed_without_fork?]
  validates :source_branch, presence: true
  validates :target_project, presence: true
  validates :target_branch, presence: true
  validates :merge_user, presence: true, if: :merge_when_build_succeeds?
  validate :validate_branches, unless: [:allow_broken, :importing?, :closed_without_fork?]
  validate :validate_fork, unless: :closed_without_fork?

  scope :by_branch, ->(branch_name) { where("(source_branch LIKE :branch) OR (target_branch LIKE :branch)", branch: branch_name) }
  scope :cared, ->(user) { where('assignee_id = :user OR author_id = :user', user: user.id) }
  scope :by_milestone, ->(milestone) { where(milestone_id: milestone) }
  scope :of_projects, ->(ids) { where(target_project_id: ids) }
  scope :from_project, ->(project) { where(source_project_id: project.id) }
  scope :merged, -> { with_state(:merged) }
  scope :closed_and_merged, -> { with_states(:closed, :merged) }
  scope :from_source_branches, ->(branches) { where(source_branch: branches) }

  scope :join_project, -> { joins(:target_project) }
  scope :references_project, -> { references(:target_project) }

  after_save :keep_around_commit

  def self.reference_prefix
    '!'
  end

  # Pattern used to extract `!123` merge request references from text
  #
  # This pattern supports cross-project references.
  def self.reference_pattern
    @reference_pattern ||= %r{
      (#{Project.reference_pattern})?
      #{Regexp.escape(reference_prefix)}(?<merge_request>\d+)
    }x
  end

  def self.link_reference_pattern
    @link_reference_pattern ||= super("merge_requests", /(?<merge_request>\d+)/)
  end

  def self.reference_valid?(reference)
    reference.to_i > 0 && reference.to_i <= Gitlab::Database::MAX_INT_VALUE
  end

  def self.project_foreign_key
    'target_project_id'
  end

  # Returns all the merge requests from an ActiveRecord:Relation.
  #
  # This method uses a UNION as it usually operates on the result of
  # ProjectsFinder#execute. PostgreSQL in particular doesn't always like queries
  # using multiple sub-queries especially when combined with an OR statement.
  # UNIONs on the other hand perform much better in these cases.
  #
  # relation - An ActiveRecord::Relation that returns a list of Projects.
  #
  # Returns an ActiveRecord::Relation.
  def self.in_projects(relation)
    source = where(source_project_id: relation).select(:id)
    target = where(target_project_id: relation).select(:id)
    union  = Gitlab::SQL::Union.new([source, target])

    where("merge_requests.id IN (#{union.to_sql})")
  end

  WIP_REGEX = /\A\s*(\[WIP\]\s*|WIP:\s*|WIP\s+)+\s*/i.freeze

  def self.work_in_progress?(title)
    !!(title =~ WIP_REGEX)
  end

  def self.wipless_title(title)
    title.sub(WIP_REGEX, "")
  end

  def self.wip_title(title)
    work_in_progress?(title) ? title : "WIP: #{title}"
  end

  def to_reference(from_project = nil)
    reference = "#{self.class.reference_prefix}#{iid}"

    if cross_project_reference?(from_project)
      reference = project.to_reference + reference
    end

    reference
  end

  def first_commit
    merge_request_diff ? merge_request_diff.first_commit : compare_commits.first
  end

  def raw_diffs(*args)
    merge_request_diff ? merge_request_diff.raw_diffs(*args) : compare.raw_diffs(*args)
  end

  def diffs(diff_options = nil)
    if compare
      compare.diffs(diff_options)
    else
      merge_request_diff.diffs(diff_options)
    end
  end

  def diff_size
    diffs(diff_options).size
  end

  def diff_base_commit
    if persisted?
      merge_request_diff.base_commit
    else
      branch_merge_base_commit
    end
  end

  # MRs created before 8.4 don't store a MergeRequestDiff#base_commit_sha,
  # but we need to get a commit for the "View file @ ..." link by deleted files,
  # so we find the likely one if we can't get the actual one.
  # This will not be the actual base commit if the target branch was merged into
  # the source branch after the merge request was created, but it is good enough
  # for the specific purpose of linking to a commit.
  # It is not good enough for use in `Gitlab::Git::DiffRefs`, which needs the
  # true base commit, so we can't simply have `#diff_base_commit` fall back on
  # this method.
  def likely_diff_base_commit
    first_commit.parent || first_commit
  end

  def diff_start_commit
    if persisted?
      merge_request_diff.start_commit
    else
      target_branch_head
    end
  end

  def diff_head_commit
    if persisted?
      merge_request_diff.head_commit
    else
      source_branch_head
    end
  end

  def diff_start_sha
    diff_start_commit.try(:sha)
  end

  def diff_base_sha
    diff_base_commit.try(:sha)
  end

  def diff_head_sha
    diff_head_commit.try(:sha)
  end

  # When importing a pull request from GitHub, the old and new branches may no
  # longer actually exist by those names, but we need to recreate the merge
  # request diff with the right source and target shas.
  # We use these attributes to force these to the intended values.
  attr_writer :target_branch_sha, :source_branch_sha

  def source_branch_head
    source_branch_ref = @source_branch_sha || source_branch
    source_project.repository.commit(source_branch_ref) if source_branch_ref
  end

  def target_branch_head
    target_branch_ref = @target_branch_sha || target_branch
    target_project.repository.commit(target_branch_ref) if target_branch_ref
  end

  def branch_merge_base_commit
    start_sha = target_branch_sha
    head_sha  = source_branch_sha

    if start_sha && head_sha
      target_project.merge_base_commit(start_sha, head_sha)
    end
  end

  def target_branch_sha
    @target_branch_sha || target_branch_head.try(:sha)
  end

  def source_branch_sha
    @source_branch_sha || source_branch_head.try(:sha)
  end

  def diff_refs
    return unless diff_start_commit || diff_base_commit

    Gitlab::Diff::DiffRefs.new(
      base_sha:  diff_base_sha,
      start_sha: diff_start_sha,
      head_sha:  diff_head_sha
    )
  end

  # Return diff_refs instance trying to not touch the git repository
  def diff_sha_refs
    if merge_request_diff && merge_request_diff.diff_refs_by_sha?
      merge_request_diff.diff_refs
    else
      diff_refs
    end
  end

  def branch_merge_base_sha
    branch_merge_base_commit.try(:sha)
  end

  def validate_branches
    if target_project == source_project && target_branch == source_branch
      errors.add :branch_conflict, "You can not use same project/branch for source and target"
    end

    if opened? || reopened?
      similar_mrs = self.target_project.merge_requests.where(source_branch: source_branch, target_branch: target_branch, source_project_id: source_project.try(:id)).opened
      similar_mrs = similar_mrs.where('id not in (?)', self.id) if self.id
      if similar_mrs.any?
        errors.add :validate_branches,
                   "Cannot Create: This merge request already exists: #{similar_mrs.pluck(:title)}"
      end
    end
  end

  def validate_fork
    return true unless target_project && source_project
    return true if target_project == source_project
    return true unless source_project_missing?

    errors.add :validate_fork,
               'Source project is not a fork of the target project'
  end

  def closed_without_fork?
    closed? && source_project_missing?
  end

  def source_project_missing?
    return false unless for_fork?
    return true unless source_project

    !source_project.forked_from?(target_project)
  end

  def reopenable?
    closed? && !source_project_missing? && source_branch_exists?
  end

  def ensure_merge_request_diff
    merge_request_diff || create_merge_request_diff
  end

  def create_merge_request_diff
    merge_request_diffs.create
    reload_merge_request_diff
  end

  def reload_merge_request_diff
    merge_request_diff(true)
  end

  def reload_diff_if_branch_changed
    if source_branch_changed? || target_branch_changed?
      reload_diff
    end
  end

  def reload_diff
    return unless open?

    old_diff_refs = self.diff_refs
    create_merge_request_diff
    MergeRequests::MergeRequestDiffCacheService.new.execute(self)
    new_diff_refs = self.diff_refs

    update_diff_notes_positions(
      old_diff_refs: old_diff_refs,
      new_diff_refs: new_diff_refs
    )
  end

  def check_if_can_be_merged
    return unless unchecked?

    can_be_merged =
      !broken? && project.repository.can_be_merged?(diff_head_sha, target_branch)

    if can_be_merged
      mark_as_mergeable
    else
      mark_as_unmergeable
    end
  end

  def merge_event
    @merge_event ||= target_project.events.where(target_id: self.id, target_type: "MergeRequest", action: Event::MERGED).last
  end

  def closed_event
    @closed_event ||= target_project.events.where(target_id: self.id, target_type: "MergeRequest", action: Event::CLOSED).last
  end

  def work_in_progress?
    self.class.work_in_progress?(title)
  end

  def wipless_title
    self.class.wipless_title(self.title)
  end

  def wip_title
    self.class.wip_title(self.title)
  end

  def mergeable?(skip_ci_check: false)
    return false unless mergeable_state?(skip_ci_check: skip_ci_check)

    check_if_can_be_merged

    can_be_merged?
  end

  def mergeable_state?(skip_ci_check: false)
    return false unless open?
    return false if work_in_progress?
    return false if broken?
    return false unless skip_ci_check || mergeable_ci_state?
    return false unless mergeable_discussions_state?

    true
  end

  def can_cancel_merge_when_build_succeeds?(current_user)
    can_be_merged_by?(current_user) || self.author == current_user
  end

  def can_remove_source_branch?(current_user)
    !source_project.protected_branch?(source_branch) &&
      !source_project.root_ref?(source_branch) &&
      Ability.allowed?(current_user, :push_code, source_project) &&
      diff_head_commit == source_branch_head
  end

  def should_remove_source_branch?
    Gitlab::Utils.to_boolean(merge_params['should_remove_source_branch'])
  end

  def force_remove_source_branch?
    Gitlab::Utils.to_boolean(merge_params['force_remove_source_branch'])
  end

  def remove_source_branch?
    should_remove_source_branch? || force_remove_source_branch?
  end

  def mr_and_commit_notes
    # Fetch comments only from last 100 commits
    commits_for_notes_limit = 100
    commit_ids = commits.last(commits_for_notes_limit).map(&:id)

    Note.where(
      "(project_id = :target_project_id AND noteable_type = 'MergeRequest' AND noteable_id = :mr_id) OR" +
      "((project_id = :source_project_id OR project_id = :target_project_id) AND noteable_type = 'Commit' AND commit_id IN (:commit_ids))",
      mr_id: id,
      commit_ids: commit_ids,
      target_project_id: target_project_id,
      source_project_id: source_project_id
    )
  end

  def discussions
    @discussions ||= self.mr_and_commit_notes.
      inc_relations_for_view.
      fresh.
      discussions
  end

  def diff_discussions
    @diff_discussions ||= self.notes.diff_notes.discussions
  end

  def find_diff_discussion(discussion_id)
    notes = self.notes.diff_notes.where(discussion_id: discussion_id).fresh.to_a
    return if notes.empty?

    Discussion.new(notes)
  end

  def discussions_resolvable?
    diff_discussions.any?(&:resolvable?)
  end

  def discussions_resolved?
    discussions_resolvable? && diff_discussions.none?(&:to_be_resolved?)
  end

  def discussions_to_be_resolved?
    discussions_resolvable? && !discussions_resolved?
  end

  def mergeable_discussions_state?
    return true unless project.only_allow_merge_if_all_discussions_are_resolved?

    !discussions_to_be_resolved?
  end

  def hook_attrs
    attrs = {
      source: source_project.try(:hook_attrs),
      target: target_project.hook_attrs,
      last_commit: nil,
      work_in_progress: work_in_progress?
    }

    if diff_head_commit
      attrs.merge!(last_commit: diff_head_commit.hook_attrs)
    end

    attributes.merge!(attrs)
  end

  def for_fork?
    target_project != source_project
  end

  def project
    target_project
  end

  # If the merge request closes any issues, save this information in the
  # `MergeRequestsClosingIssues` model. This is a performance optimization.
  # Calculating this information for a number of merge requests requires
  # running `ReferenceExtractor` on each of them separately.
  # This optimization does not apply to issues from external sources.
  def cache_merge_request_closes_issues!(current_user = self.author)
    return if project.has_external_issue_tracker?

    transaction do
      self.merge_requests_closing_issues.delete_all

      closes_issues(current_user).each do |issue|
        self.merge_requests_closing_issues.create!(issue: issue)
      end
    end
  end

  def closes_issue?(issue)
    closes_issues.include?(issue)
  end

  # Return the set of issues that will be closed if this merge request is accepted.
  def closes_issues(current_user = self.author)
    if target_branch == project.default_branch
      messages = [description]
      messages.concat(commits.map(&:safe_message)) if merge_request_diff

      Gitlab::ClosingIssueExtractor.new(project, current_user).
        closed_by_message(messages.join("\n"))
    else
      []
    end
  end

  def target_project_path
    if target_project
      target_project.path_with_namespace
    else
      "(removed)"
    end
  end

  def source_project_path
    if source_project
      source_project.path_with_namespace
    else
      "(removed)"
    end
  end

  def source_project_namespace
    if source_project && source_project.namespace
      source_project.namespace.path
    else
      "(removed)"
    end
  end

  def target_project_namespace
    if target_project && target_project.namespace
      target_project.namespace.path
    else
      "(removed)"
    end
  end

  def source_branch_exists?
    return false unless self.source_project

    self.source_project.repository.branch_names.include?(self.source_branch)
  end

  def target_branch_exists?
    return false unless self.target_project

    self.target_project.repository.branch_names.include?(self.target_branch)
  end

  # Reset merge request events cache
  #
  # Since we do cache @event we need to reset cache in special cases:
  # * when a merge request is updated
  # Events cache stored like  events/23-20130109142513.
  # The cache key includes updated_at timestamp.
  # Thus it will automatically generate a new fragment
  # when the event is updated because the key changes.
  def reset_events_cache
    Event.reset_event_cache_for(self)
  end

  def merge_commit_message
    message = "Merge branch '#{source_branch}' into '#{target_branch}'\n\n"
    message << "#{title}\n\n"
    message << "#{description}\n\n" if description.present?
    message << "See merge request #{to_reference}"

    message
  end

  def reset_merge_when_build_succeeds
    return unless merge_when_build_succeeds?

    self.merge_when_build_succeeds = false
    self.merge_user = nil
    if merge_params
      merge_params.delete('should_remove_source_branch')
      merge_params.delete('commit_message')
    end

    self.save
  end

  # Return array of possible target branches
  # depends on target project of MR
  def target_branches
    if target_project.nil?
      []
    else
      target_project.repository.branch_names
    end
  end

  # Return array of possible source branches
  # depends on source project of MR
  def source_branches
    if source_project.nil?
      []
    else
      source_project.repository.branch_names
    end
  end

  def locked_long_ago?
    return false unless locked?

    locked_at.nil? || locked_at < (Time.now - 1.day)
  end

  def has_ci?
    source_project.try(:ci_service) && commits.any?
  end

  def branch_missing?
    !source_branch_exists? || !target_branch_exists?
  end

  def broken?
    self.commits.blank? || branch_missing? || cannot_be_merged?
  end

  def can_be_merged_by?(user)
    access = ::Gitlab::UserAccess.new(user, project: project)
    access.can_push_to_branch?(target_branch) || access.can_merge_to_branch?(target_branch)
  end

  def can_be_merged_via_command_line_by?(user)
    access = ::Gitlab::UserAccess.new(user, project: project)
    access.can_push_to_branch?(target_branch)
  end

  def mergeable_ci_state?
    return true unless project.only_allow_merge_if_build_succeeds?

    !pipeline || pipeline.success? || pipeline.skipped?
  end

  def environments
    return [] unless diff_head_commit

    @environments ||= begin
      target_envs = target_project.environments_for(
        target_branch, commit: diff_head_commit, with_tags: true)

      source_envs = source_project.environments_for(
        source_branch, commit: diff_head_commit) if source_project

      (target_envs.to_a + source_envs.to_a).uniq
    end
  end

  def state_human_name
    if merged?
      "Merged"
    elsif closed?
      "Closed"
    else
      "Open"
    end
  end

  def state_icon_name
    if merged?
      "check"
    elsif closed?
      "times"
    else
      "circle-o"
    end
  end

  def fetch_ref
    target_project.repository.fetch_ref(
      source_project.repository.path_to_repo,
      "refs/heads/#{source_branch}",
      ref_path
    )
  end

  def ref_path
    "refs/merge-requests/#{iid}/head"
  end

  def ref_fetched?
    project.repository.ref_exists?(ref_path)
  end

  def ensure_ref_fetched
    fetch_ref unless ref_fetched?
  end

  def in_locked_state
    begin
      lock_mr
      yield
    ensure
      unlock_mr if locked?
    end
  end

  def diverged_commits_count
    cache = Rails.cache.read(:"merge_request_#{id}_diverged_commits")

    if cache.blank? || cache[:source_sha] != source_branch_sha || cache[:target_sha] != target_branch_sha
      cache = {
        source_sha: source_branch_sha,
        target_sha: target_branch_sha,
        diverged_commits_count: compute_diverged_commits_count
      }
      Rails.cache.write(:"merge_request_#{id}_diverged_commits", cache)
    end

    cache[:diverged_commits_count]
  end

  def compute_diverged_commits_count
    return 0 unless source_branch_sha && target_branch_sha

    Gitlab::Git::Commit.between(target_project.repository.raw_repository, source_branch_sha, target_branch_sha).size
  end
  private :compute_diverged_commits_count

  def diverged_from_target_branch?
    diverged_commits_count > 0
  end

  def commits_sha
    commits.map(&:sha)
  end

  def pipeline
    return unless diff_head_sha && source_project

    @pipeline ||= source_project.pipeline_for(source_branch, diff_head_sha)
  end

  def all_pipelines
    return unless source_project

    @all_pipelines ||= source_project.pipelines
      .where(sha: all_commits_sha, ref: source_branch)
      .order(id: :desc)
  end

  # Note that this could also return SHA from now dangling commits
  #
  def all_commits_sha
    if persisted?
      merge_request_diffs.flat_map(&:commits_sha).uniq
    elsif compare_commits
      compare_commits.to_a.reverse.map(&:id)
    else
      [diff_head_sha]
    end
  end

  def merge_commit
    @merge_commit ||= project.commit(merge_commit_sha) if merge_commit_sha
  end

  def can_be_reverted?(current_user = nil)
    merge_commit && !merge_commit.has_been_reverted?(current_user, self)
  end

  def can_be_cherry_picked?
    merge_commit
  end

  def has_complete_diff_refs?
    diff_sha_refs && diff_sha_refs.complete?
  end

  def update_diff_notes_positions(old_diff_refs:, new_diff_refs:)
    return unless has_complete_diff_refs?
    return if new_diff_refs == old_diff_refs

    active_diff_notes = self.notes.diff_notes.select do |note|
      note.new_diff_note? && note.active?(old_diff_refs)
    end

    return if active_diff_notes.empty?

    paths = active_diff_notes.flat_map { |n| n.diff_file.paths }.uniq

    service = Notes::DiffPositionUpdateService.new(
      self.project,
      nil,
      old_diff_refs: old_diff_refs,
      new_diff_refs: new_diff_refs,
      paths: paths
    )

    active_diff_notes.each do |note|
      service.execute(note)
      Gitlab::Timeless.timeless(note, &:save)
    end
  end

  def keep_around_commit
    project.repository.keep_around(self.merge_commit_sha)
  end

  def conflicts
    @conflicts ||= Gitlab::Conflict::FileCollection.new(self)
  end

  def conflicts_can_be_resolved_by?(user)
    access = ::Gitlab::UserAccess.new(user, project: source_project)
    access.can_push_to_branch?(source_branch)
  end

  def conflicts_can_be_resolved_in_ui?
    return @conflicts_can_be_resolved_in_ui if defined?(@conflicts_can_be_resolved_in_ui)

    return @conflicts_can_be_resolved_in_ui = false unless cannot_be_merged?
    return @conflicts_can_be_resolved_in_ui = false unless has_complete_diff_refs?

    begin
      # Try to parse each conflict. If the MR's mergeable status hasn't been updated,
      # ensure that we don't say there are conflicts to resolve when there are no conflict
      # files.
      conflicts.files.each(&:lines)
      @conflicts_can_be_resolved_in_ui = conflicts.files.length > 0
    rescue Rugged::OdbError, Gitlab::Conflict::Parser::UnresolvableError, Gitlab::Conflict::FileCollection::ConflictSideMissing
      @conflicts_can_be_resolved_in_ui = false
    end
  end
end
