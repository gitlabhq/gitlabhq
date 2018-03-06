class MergeRequest < ActiveRecord::Base
  include NonatomicInternalId
  include Issuable
  include Noteable
  include Referable
  include Elastic::MergeRequestsSearch
  include IgnorableColumn
  include TimeTrackable
  include ManualInverseAssociation
  include EachBatch
  include ThrottledTouch
  include Gitlab::Utils::StrongMemoize

  ignore_column :locked_at,
                :ref_fetched,
                :deleted_at

  include ::EE::MergeRequest
  include Elastic::MergeRequestsSearch

  belongs_to :target_project, class_name: "Project"
  belongs_to :source_project, class_name: "Project"
  belongs_to :merge_user, class_name: "User"

  has_many :merge_request_diffs

  has_one :merge_request_diff,
    -> { order('merge_request_diffs.id DESC') }, inverse_of: :merge_request

  belongs_to :latest_merge_request_diff, class_name: 'MergeRequestDiff'
  manual_inverse_association :latest_merge_request_diff, :merge_request

  # This is the same as latest_merge_request_diff unless:
  # 1. There are arguments - in which case we might be trying to force-reload.
  # 2. This association is already loaded.
  # 3. The latest diff does not exist.
  #
  # The second one in particular is important - MergeRequestDiff#merge_request
  # is the inverse of MergeRequest#merge_request_diff, which means it may not be
  # the latest diff, because we could have loaded any diff from this particular
  # MR. If we haven't already loaded a diff, then it's fine to load the latest.
  def merge_request_diff(*args)
    fallback = latest_merge_request_diff if args.empty? && !association(:merge_request_diff).loaded?

    fallback || super
  end

  belongs_to :head_pipeline, foreign_key: "head_pipeline_id", class_name: "Ci::Pipeline"

  has_many :events, as: :target, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  has_many :merge_requests_closing_issues,
    class_name: 'MergeRequestsClosingIssues',
    dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  belongs_to :assignee, class_name: "User"

  serialize :merge_params, Hash # rubocop:disable Cop/ActiveRecordSerialize

  after_create :ensure_merge_request_diff, unless: :importing?
  after_update :clear_memoized_shas
  after_update :reload_diff_if_branch_changed

  # When this attribute is true some MR validation is ignored
  # It allows us to close or modify broken merge requests
  attr_accessor :allow_broken

  # Temporary fields to store compare vars
  # when creating new merge request
  attr_accessor :can_be_created, :compare_commits, :diff_options, :compare

  state_machine :state, initial: :opened do
    event :close do
      transition [:opened] => :closed
    end

    event :mark_as_merged do
      transition [:opened, :locked] => :merged
    end

    event :reopen do
      transition closed: :opened
    end

    event :lock_mr do
      transition [:opened] => :locked
    end

    event :unlock_mr do
      transition locked: :opened
    end

    before_transition any => :opened do |merge_request|
      merge_request.merge_jid = nil

      merge_request.run_after_commit do
        UpdateHeadPipelineForMergeRequestWorker.perform_async(merge_request.id)
      end
    end

    state :opened
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
  validates :merge_user, presence: true, if: :merge_when_pipeline_succeeds?, unless: :importing?
  validate :validate_branches, unless: [:allow_broken, :importing?, :closed_without_fork?]
  validate :validate_fork, unless: :closed_without_fork?
  validate :validate_approvals_before_merge, unless: :importing?
  validate :validate_target_project, on: :create

  scope :by_source_or_target_branch, ->(branch_name) do
    where("source_branch = :branch OR target_branch = :branch", branch: branch_name)
  end
  scope :by_milestone, ->(milestone) { where(milestone_id: milestone) }
  scope :of_projects, ->(ids) { where(target_project_id: ids) }
  scope :from_project, ->(project) { where(source_project_id: project.id) }
  scope :merged, -> { with_state(:merged) }
  scope :closed_and_merged, -> { with_states(:closed, :merged) }
  scope :from_source_branches, ->(branches) { where(source_branch: branches) }
  scope :by_commit_sha, ->(sha) do
    where('EXISTS (?)', MergeRequestDiff.select(1).where('merge_requests.latest_merge_request_diff_id = merge_request_diffs.id').by_commit_sha(sha)).reorder(nil)
  end
  scope :join_project, -> { joins(:target_project) }
  scope :references_project, -> { references(:target_project) }
  scope :assigned, -> { where("assignee_id IS NOT NULL") }
  scope :unassigned, -> { where("assignee_id IS NULL") }
  scope :assigned_to, ->(u) { where(assignee_id: u.id)}

  participant :participant_approvers
  participant :assignee

  after_save :keep_around_commit

  def self.reference_prefix
    '!'
  end

  def rebase_in_progress?
    strong_memoize(:rebase_in_progress) do
      # The source project can be deleted
      next false unless source_project

      source_project.repository.rebase_in_progress?(id)
    end
  end

  # Use this method whenever you need to make sure the head_pipeline is synced with the
  # branch head commit, for example checking if a merge request can be merged.
  # For more information check: https://gitlab.com/gitlab-org/gitlab-ce/issues/40004
  def actual_head_pipeline
    head_pipeline&.sha == diff_head_sha ? head_pipeline : nil
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
    # unscoping unnecessary conditions that'll be applied
    # when executing `where("merge_requests.id IN (#{union.to_sql})")`
    source = unscoped.where(source_project_id: relation).select(:id)
    target = unscoped.where(target_project_id: relation).select(:id)
    union  = Gitlab::SQL::Union.new([source, target])

    where("merge_requests.id IN (#{union.to_sql})") # rubocop:disable GitlabSecurity/SqlInjection
  end

  # This is used after project import, to reset the IDs to the correct
  # values. It is not intended to be called without having already scoped the
  # relation.
  def self.set_latest_merge_request_diff_ids!
    update = '
      latest_merge_request_diff_id = (
        SELECT MAX(id)
        FROM merge_request_diffs
        WHERE merge_requests.id = merge_request_diffs.merge_request_id
      )'.squish

    self.each_batch do |batch|
      batch.update_all(update)
    end
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

  # Verifies if title has changed not taking into account WIP prefix
  # for merge requests.
  def wipless_title_changed(old_title)
    self.class.wipless_title(old_title) != self.wipless_title
  end

  def hook_attrs
    Gitlab::HookData::MergeRequestBuilder.new(self).build
  end

  # Returns a Hash of attributes to be used for Twitter card metadata
  def card_attributes
    {
      'Author'   => author.try(:name),
      'Assignee' => assignee.try(:name)
    }
  end

  # These method are needed for compatibility with issues to not mess view and other code
  def assignees
    Array(assignee)
  end

  def assignee_ids
    Array(assignee_id)
  end

  def assignee_ids=(ids)
    write_attribute(:assignee_id, ids.last)
  end

  def assignee_or_author?(user)
    author_id == user.id || assignee_id == user.id
  end

  def participant_approvers
    requires_approve? ? approvers_left : []
  end

  # `from` argument can be a Namespace or Project.
  def to_reference(from = nil, full: false)
    reference = "#{self.class.reference_prefix}#{iid}"

    "#{project.to_reference(from, full: full)}#{reference}"
  end

  def commits
    if persisted?
      merge_request_diff.commits
    elsif compare_commits
      compare_commits.reverse
    else
      []
    end
  end

  def commits_count
    if persisted?
      merge_request_diff.commits_count
    elsif compare_commits
      compare_commits.size
    else
      0
    end
  end

  def commit_shas
    if persisted?
      merge_request_diff.commit_shas
    elsif compare_commits
      compare_commits.to_a.reverse.map(&:sha)
    else
      Array(diff_head_sha)
    end
  end

  # Calls `MergeWorker` to proceed with the merge process and
  # updates `merge_jid` with the MergeWorker#jid.
  # This helps tracking enqueued and ongoing merge jobs.
  def merge_async(user_id, params)
    jid = MergeWorker.perform_async(id, user_id, params)
    update_column(:merge_jid, jid)
  end

  def first_commit
    merge_request_diff ? merge_request_diff.first_commit : compare_commits.first
  end

  def raw_diffs(*args)
    merge_request_diff ? merge_request_diff.raw_diffs(*args) : compare.raw_diffs(*args)
  end

  def diffs(diff_options = {})
    if compare
      # When saving MR diffs, `expanded` is implicitly added (because we need
      # to save the entire contents to the DB), so add that here for
      # consistency.
      compare.diffs(diff_options.merge(expanded: true))
    else
      merge_request_diff.diffs(diff_options)
    end
  end

  def diff_size
    # Calling `merge_request_diff.diffs.real_size` will also perform
    # highlighting, which we don't need here.
    merge_request_diff&.real_size || diffs.real_size
  end

  def diff_base_commit
    if persisted?
      merge_request_diff.base_commit
    else
      branch_merge_base_commit
    end
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
    if persisted?
      merge_request_diff.start_commit_sha
    else
      target_branch_head.try(:sha)
    end
  end

  def diff_base_sha
    if persisted?
      merge_request_diff.base_commit_sha
    else
      branch_merge_base_commit.try(:sha)
    end
  end

  def diff_head_sha
    if persisted?
      merge_request_diff.head_commit_sha
    else
      source_branch_head.try(:sha)
    end
  end

  # When importing a pull request from GitHub, the old and new branches may no
  # longer actually exist by those names, but we need to recreate the merge
  # request diff with the right source and target shas.
  # We use these attributes to force these to the intended values.
  attr_writer :target_branch_sha, :source_branch_sha

  def source_branch_ref
    return @source_branch_sha if @source_branch_sha
    return unless source_branch

    Gitlab::Git::BRANCH_REF_PREFIX + source_branch
  end

  def target_branch_ref
    return @target_branch_sha if @target_branch_sha
    return unless target_branch

    Gitlab::Git::BRANCH_REF_PREFIX + target_branch
  end

  def source_branch_head
    strong_memoize(:source_branch_head) do
      if source_project && source_branch_ref
        source_project.repository.commit(source_branch_ref)
      end
    end
  end

  def target_branch_head
    strong_memoize(:target_branch_head) do
      target_project.repository.commit(target_branch_ref)
    end
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
    if persisted?
      merge_request_diff.diff_refs
    else
      Gitlab::Diff::DiffRefs.new(
        base_sha:  diff_base_sha,
        start_sha: diff_start_sha,
        head_sha:  diff_head_sha
      )
    end
  end

  def branch_merge_base_sha
    branch_merge_base_commit.try(:sha)
  end

  def validate_branches
    if target_project == source_project && target_branch == source_branch
      errors.add :branch_conflict, "You can not use same project/branch for source and target"
    end

    if opened?
      similar_mrs = self.target_project.merge_requests.where(source_branch: source_branch, target_branch: target_branch, source_project_id: source_project.try(:id)).opened
      similar_mrs = similar_mrs.where('id not in (?)', self.id) if self.id
      if similar_mrs.any?
        errors.add :validate_branches,
                   "Cannot Create: This merge request already exists: #{similar_mrs.pluck(:title)}"
      end
    end
  end

  def validate_target_project
    return true if target_project.merge_requests_enabled?

    errors.add :base, 'Target project has disabled merge requests'
  end

  def validate_fork
    return true unless target_project && source_project
    return true if target_project == source_project
    return true unless source_project_missing?

    errors.add :validate_fork,
               'Source project is not a fork of the target project'
  end

  def merge_ongoing?
    # While the MergeRequest is locked, it should present itself as 'merge ongoing'.
    # The unlocking process is handled by StuckMergeJobsWorker scheduled in Cron.
    return true if locked?

    !!merge_jid && !merged? && Gitlab::SidekiqStatus.running?(merge_jid)
  end

  def closed_without_fork?
    closed? && source_project_missing?
  end

  def source_project_missing?
    return false unless for_fork?
    return true unless source_project

    !source_project.in_fork_network_of?(target_project)
  end

  def validate_approvals_before_merge
    return true unless approvals_before_merge
    return true unless target_project

    # Approvals disabled
    if target_project.approvals_before_merge == 0
      errors.add :validate_approvals_before_merge,
                 'Approvals disabled for target project'
    elsif approvals_before_merge > target_project.approvals_before_merge
      true
    else
      errors.add :validate_approvals_before_merge,
                 'Number of approvals must be greater than those on target project'
    end
  end

  def reopenable?
    closed? && !source_project_missing? && source_branch_exists?
  end

  def ensure_merge_request_diff
    merge_request_diff || create_merge_request_diff
  end

  def create_merge_request_diff
    fetch_ref!

    # n+1: https://gitlab.com/gitlab-org/gitlab-ce/issues/37435
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      merge_request_diffs.create
      reload_merge_request_diff
    end
  end

  def reload_merge_request_diff
    merge_request_diff(true)
  end

  def merge_request_diff_for(diff_refs_or_sha)
    @merge_request_diffs_by_diff_refs_or_sha ||= Hash.new do |h, diff_refs_or_sha|
      diffs = merge_request_diffs.viewable
      h[diff_refs_or_sha] =
        if diff_refs_or_sha.is_a?(Gitlab::Diff::DiffRefs)
          diffs.find_by_diff_refs(diff_refs_or_sha)
        else
          diffs.find_by(head_commit_sha: diff_refs_or_sha)
        end
    end

    @merge_request_diffs_by_diff_refs_or_sha[diff_refs_or_sha]
  end

  def version_params_for(diff_refs)
    if diff = merge_request_diff_for(diff_refs)
      { diff_id: diff.id }
    elsif diff = merge_request_diff_for(diff_refs.head_sha)
      {
        diff_id: diff.id,
        start_sha: diff_refs.start_sha
      }
    end
  end

  def clear_memoized_shas
    @target_branch_sha = @source_branch_sha = nil

    clear_memoization(:source_branch_head)
    clear_memoization(:target_branch_head)
  end

  def reload_diff_if_branch_changed
    if (source_branch_changed? || target_branch_changed?) &&
        (source_branch_head && target_branch_head)
      reload_diff
    end
  end

  def reload_diff(current_user = nil)
    return unless open?

    old_diff_refs = self.diff_refs
    new_diff = create_merge_request_diff

    MergeRequests::MergeRequestDiffCacheService.new.execute(self, new_diff)

    new_diff_refs = self.diff_refs

    update_diff_discussion_positions(
      old_diff_refs: old_diff_refs,
      new_diff_refs: new_diff_refs,
      current_user: current_user
    )
  end

  def check_if_can_be_merged
    return unless unchecked? && Gitlab::Database.read_write?

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
    return false unless approved?
    return false unless mergeable_state?(skip_ci_check: skip_ci_check)

    check_if_can_be_merged

    can_be_merged? && !should_be_rebased?
  end

  def mergeable_state?(skip_ci_check: false, skip_discussions_check: false)
    return false unless open?
    return false if work_in_progress?
    return false if broken?
    return false unless skip_ci_check || mergeable_ci_state?
    return false unless skip_discussions_check || mergeable_discussions_state?

    true
  end

  def ff_merge_possible?
    project.repository.ancestor?(target_branch_sha, diff_head_sha)
  end

  def should_be_rebased?
    project.ff_merge_must_be_possible? && !ff_merge_possible?
  end

  def can_cancel_merge_when_pipeline_succeeds?(current_user)
    can_be_merged_by?(current_user) || self.author == current_user
  end

  def can_remove_source_branch?(current_user)
    !ProtectedBranch.protected?(source_project, source_branch) &&
      !source_project.root_ref?(source_branch) &&
      Ability.allowed?(current_user, :push_code, source_project) &&
      diff_head_sha == source_branch_head.try(:sha)
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

  def related_notes
    # Fetch comments only from last 100 commits
    commits_for_notes_limit = 100
    commit_ids = commit_shas.take(commits_for_notes_limit)

    commit_notes = Note
      .except(:order)
      .where(project_id: [source_project_id, target_project_id])
      .for_commit_id(commit_ids)

    # We're using a UNION ALL here since this results in better performance
    # compared to using OR statements. We're using UNION ALL since the queries
    # used won't produce any duplicates (e.g. a note for a commit can't also be
    # a note for an MR).
    union = Gitlab::SQL::Union
      .new([notes, commit_notes], remove_duplicates: false)
      .to_sql

    Note.from("(#{union}) #{Note.table_name}")
      .includes(:noteable)
  end

  alias_method :discussion_notes, :related_notes

  def mergeable_discussions_state?
    return true unless project.only_allow_merge_if_all_discussions_are_resolved?

    !discussions_to_be_resolved?
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
  def cache_merge_request_closes_issues!(current_user)
    return unless project.issues_enabled?

    transaction do
      self.merge_requests_closing_issues.delete_all

      closes_issues(current_user).each do |issue|
        next if issue.is_a?(ExternalIssue)

        self.merge_requests_closing_issues.create!(issue: issue)
      end
    end
  end

  # Return the set of issues that will be closed if this merge request is accepted.
  def closes_issues(current_user = self.author)
    if target_branch == project.default_branch
      messages = [title, description]
      messages.concat(commits.map(&:safe_message)) if merge_request_diff

      Gitlab::ClosingIssueExtractor.new(project, current_user)
        .closed_by_message(messages.join("\n"))
    else
      []
    end
  end

  def issues_mentioned_but_not_closing(current_user)
    return [] unless target_branch == project.default_branch

    ext = Gitlab::ReferenceExtractor.new(project, current_user)
    ext.analyze("#{title}\n#{description}")

    ext.issues - closes_issues(current_user)
  end

  def target_project_path
    if target_project
      target_project.full_path
    else
      "(removed)"
    end
  end

  def source_project_path
    if source_project
      source_project.full_path
    else
      "(removed)"
    end
  end

  def source_project_namespace
    if source_project && source_project.namespace
      source_project.namespace.full_path
    else
      "(removed)"
    end
  end

  def target_project_namespace
    if target_project && target_project.namespace
      target_project.namespace.full_path
    else
      "(removed)"
    end
  end

  def source_branch_exists?
    return false unless self.source_project

    self.source_project.repository.branch_exists?(self.source_branch)
  end

  def target_branch_exists?
    return false unless self.target_project

    self.target_project.repository.branch_exists?(self.target_branch)
  end

  def merge_commit_message(include_description: false)
    closes_issues_references = closes_issues.map do |issue|
      issue.to_reference(target_project)
    end

    message = [
      "Merge branch '#{source_branch}' into '#{target_branch}'",
      title
    ]

    if !include_description && closes_issues_references.present?
      message << "Closes #{closes_issues_references.to_sentence}"
    end

    message << "#{description}" if include_description && description.present?
    message << "See merge request #{to_reference(full: true)}"

    message.join("\n\n")
  end

  def reset_merge_when_pipeline_succeeds
    return unless merge_when_pipeline_succeeds?

    self.merge_when_pipeline_succeeds = false
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

  def has_ci?
    return false if has_no_commits?

    !!(head_pipeline_id || all_pipelines.any? || source_project&.ci_service)
  end

  def branch_missing?
    !source_branch_exists? || !target_branch_exists?
  end

  def broken?
    has_no_commits? || branch_missing? || cannot_be_merged?
  end

  def can_be_merged_by?(user)
    access = ::Gitlab::UserAccess.new(user, project: project)
    access.can_update_branch?(target_branch)
  end

  def can_be_merged_via_command_line_by?(user)
    access = ::Gitlab::UserAccess.new(user, project: project)
    access.can_push_to_branch?(target_branch)
  end

  def mergeable_ci_state?
    return true unless project.only_allow_merge_if_pipeline_succeeds?
    return true unless head_pipeline

    actual_head_pipeline&.success? || actual_head_pipeline&.skipped?
  end

  def environments_for(current_user)
    return [] unless diff_head_commit

    @environments ||= Hash.new do |h, current_user|
      envs = EnvironmentsFinder.new(target_project, current_user,
        ref: target_branch, commit: diff_head_commit, with_tags: true).execute

      if source_project
        envs.concat EnvironmentsFinder.new(source_project, current_user,
          ref: source_branch, commit: diff_head_commit).execute
      end

      h[current_user] = envs.uniq
    end

    @environments[current_user]
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
      "git-merge"
    elsif closed?
      "close"
    else
      "issue-open-m"
    end
  end

  def fetch_ref!
    target_project.repository.fetch_source_branch!(source_project.repository, source_branch, ref_path)
  end

  def ref_path
    "refs/#{Repository::REF_MERGE_REQUEST}/#{iid}/head"
  end

  def in_locked_state
    begin
      lock_mr
      yield
    ensure
      unlock_mr
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

    target_project.repository
      .count_commits_between(source_branch_sha, target_branch_sha)
  end
  private :compute_diverged_commits_count

  def diverged_from_target_branch?
    diverged_commits_count > 0
  end

  def all_pipelines
    return Ci::Pipeline.none unless source_project

    @all_pipelines ||= source_project.pipelines
      .where(sha: all_commit_shas, ref: source_branch)
      .order(id: :desc)
  end

  def all_commits
    # MySQL doesn't support LIMIT in a subquery.
    diffs_relation = if Gitlab::Database.postgresql?
                       merge_request_diffs.recent
                     else
                       merge_request_diffs
                     end

    MergeRequestDiffCommit
      .where(merge_request_diff: diffs_relation)
      .limit(10_000)
  end

  # Note that this could also return SHA from now dangling commits
  #
  def all_commit_shas
    @all_commit_shas ||= begin
      return commit_shas unless persisted?

      all_commits.pluck(:sha).uniq
    end
  end

  def merge_commit
    @merge_commit ||= project.commit(merge_commit_sha) if merge_commit_sha
  end

  def can_be_reverted?(current_user)
    return false unless merge_commit

    merged_at = metrics&.merged_at
    notes_association = notes_with_associations

    if merged_at
      # It is not guaranteed that Note#created_at will be strictly later than
      # MergeRequestMetric#merged_at. Nanoseconds on MySQL may break this
      # comparison, as will a HA environment if clocks are not *precisely*
      # synchronized. Add a minute's leeway to compensate for both possibilities
      cutoff = merged_at - 1.minute

      notes_association = notes_association.where('created_at >= ?', cutoff)
    end

    !merge_commit.has_been_reverted?(current_user, notes_association)
  end

  def can_be_cherry_picked?
    merge_commit.present?
  end

  def has_complete_diff_refs?
    diff_refs && diff_refs.complete?
  end

  def update_diff_discussion_positions(old_diff_refs:, new_diff_refs:, current_user: nil)
    return unless has_complete_diff_refs?
    return if new_diff_refs == old_diff_refs

    active_diff_discussions = self.notes.new_diff_notes.discussions.select do |discussion|
      discussion.active?(old_diff_refs)
    end
    return if active_diff_discussions.empty?

    paths = active_diff_discussions.flat_map { |n| n.diff_file.paths }.uniq

    service = Discussions::UpdateDiffPositionService.new(
      self.project,
      current_user,
      old_diff_refs: old_diff_refs,
      new_diff_refs: new_diff_refs,
      paths: paths
    )

    active_diff_discussions.each do |discussion|
      service.execute(discussion)
    end

    if project.resolve_outdated_diff_discussions?
      MergeRequests::ResolvedDiscussionNotificationService
        .new(project, current_user)
        .execute(self)
    end
  end

  def keep_around_commit
    project.repository.keep_around(self.merge_commit_sha)
  end

  def has_commits?
    merge_request_diff && commits_count > 0
  end

  def has_no_commits?
    !has_commits?
  end

  def mergeable_with_quick_action?(current_user, autocomplete_precheck: false, last_diff_sha: nil)
    return false unless can_be_merged_by?(current_user)

    return true if autocomplete_precheck

    return false unless mergeable?(skip_ci_check: true)
    return false if actual_head_pipeline && !(actual_head_pipeline.success? || actual_head_pipeline.active?)
    return false if last_diff_sha != diff_head_sha

    true
  end

  def base_pipeline
    @base_pipeline ||= project.pipelines.find_by(sha: merge_request_diff&.base_commit_sha)
  end

  def update_project_counter_caches
    Projects::OpenMergeRequestsCountService.new(target_project).refresh_cache
  end

  def first_contribution?
    return false if project.team.max_member_access(author_id) > Gitlab::Access::GUEST

    project.merge_requests.merged.where(author_id: author_id).empty?
  end

  def allow_maintainer_to_push
    maintainer_push_possible? && super
  end

  alias_method :allow_maintainer_to_push?, :allow_maintainer_to_push

  def maintainer_push_possible?
    source_project.present? && for_fork? &&
      target_project.visibility_level > Gitlab::VisibilityLevel::PRIVATE &&
      source_project.visibility_level > Gitlab::VisibilityLevel::PRIVATE &&
      !ProtectedBranch.protected?(source_project, source_branch)
  end

  def can_allow_maintainer_to_push?(user)
    maintainer_push_possible? &&
      Ability.allowed?(user, :push_code, source_project)
  end
end
