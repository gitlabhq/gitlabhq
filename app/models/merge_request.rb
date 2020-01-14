# frozen_string_literal: true

class MergeRequest < ApplicationRecord
  include AtomicInternalId
  include IidRoutes
  include Issuable
  include Noteable
  include Referable
  include Presentable
  include TimeTrackable
  include ManualInverseAssociation
  include EachBatch
  include ThrottledTouch
  include Gitlab::Utils::StrongMemoize
  include LabelEventable
  include ReactiveCaching
  include FromUnion
  include DeprecatedAssignee
  include ShaAttribute
  include IgnorableColumns

  sha_attribute :squash_commit_sha

  self.reactive_cache_key = ->(model) { [model.project.id, model.iid] }
  self.reactive_cache_refresh_interval = 10.minutes
  self.reactive_cache_lifetime = 10.minutes

  SORTING_PREFERENCE_FIELD = :merge_requests_sort

  belongs_to :target_project, class_name: "Project"
  belongs_to :source_project, class_name: "Project"
  belongs_to :merge_user, class_name: "User"

  has_internal_id :iid, scope: :target_project, track_if: -> { !importing? }, init: ->(s) { s&.target_project&.merge_requests&.maximum(:iid) }

  has_many :merge_request_diffs

  has_many :merge_request_milestones
  has_many :milestones, through: :merge_request_milestones

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
  def merge_request_diff
    fallback = latest_merge_request_diff unless association(:merge_request_diff).loaded?

    fallback || super
  end

  belongs_to :head_pipeline, foreign_key: "head_pipeline_id", class_name: "Ci::Pipeline"

  has_many :events, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  has_many :merge_requests_closing_issues,
    class_name: 'MergeRequestsClosingIssues',
    dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  has_many :cached_closes_issues, through: :merge_requests_closing_issues, source: :issue
  has_many :pipelines_for_merge_request, foreign_key: 'merge_request_id', class_name: 'Ci::Pipeline'
  has_many :suggestions, through: :notes
  has_many :unresolved_notes, -> { unresolved }, as: :noteable, class_name: 'Note'

  has_many :merge_request_assignees
  has_many :assignees, class_name: "User", through: :merge_request_assignees
  has_many :user_mentions, class_name: "MergeRequestUserMention"

  has_many :deployment_merge_requests

  # These are deployments created after the merge request has been merged, and
  # the merge request was tracked explicitly (instead of implicitly using a CI
  # build).
  has_many :deployments,
    through: :deployment_merge_requests

  KNOWN_MERGE_PARAMS = [
    :auto_merge_strategy,
    :should_remove_source_branch,
    :force_remove_source_branch,
    :commit_message,
    :squash_commit_message,
    :sha
  ].freeze
  serialize :merge_params, Hash # rubocop:disable Cop/ActiveRecordSerialize

  after_create :ensure_merge_request_diff
  after_update :clear_memoized_shas
  after_update :reload_diff_if_branch_changed
  after_save :ensure_metrics, unless: :importing?
  after_commit :expire_etag_cache, unless: :importing?

  # When this attribute is true some MR validation is ignored
  # It allows us to close or modify broken merge requests
  attr_accessor :allow_broken

  # Temporary fields to store compare vars
  # when creating new merge request
  attr_accessor :can_be_created, :compare_commits, :diff_options, :compare

  # Keep states definition to be evaluated before the state_machine block to avoid spec failures.
  # If this gets evaluated after, the `merged` and `locked` states which are overrided can be nil.
  def self.available_state_names
    super + [:merged, :locked]
  end

  state_machine :state_id, initial: :opened, initialize: false do
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
    end

    after_transition any => :opened do |merge_request|
      merge_request.run_after_commit do
        UpdateHeadPipelineForMergeRequestWorker.perform_async(merge_request.id)
      end
    end

    state :opened, value: MergeRequest.available_states[:opened]
    state :closed, value: MergeRequest.available_states[:closed]
    state :merged, value: MergeRequest.available_states[:merged]
    state :locked, value: MergeRequest.available_states[:locked]
  end

  # Alias to state machine .with_state_id method
  # This needs to be defined after the state machine block to avoid errors
  class << self
    alias_method :with_state, :with_state_id
    alias_method :with_states, :with_state_ids
  end

  state_machine :merge_status, initial: :unchecked do
    event :mark_as_unchecked do
      transition [:can_be_merged, :unchecked] => :unchecked
      transition [:cannot_be_merged, :cannot_be_merged_recheck] => :cannot_be_merged_recheck
    end

    event :mark_as_mergeable do
      transition [:unchecked, :cannot_be_merged_recheck] => :can_be_merged
    end

    event :mark_as_unmergeable do
      transition [:unchecked, :cannot_be_merged_recheck] => :cannot_be_merged
    end

    state :unchecked
    state :cannot_be_merged_recheck
    state :can_be_merged
    state :cannot_be_merged

    around_transition do |merge_request, transition, block|
      Gitlab::Timeless.timeless(merge_request, &block)
    end

    # rubocop: disable CodeReuse/ServiceClass
    after_transition unchecked: :cannot_be_merged do |merge_request, transition|
      if merge_request.notify_conflict?
        NotificationService.new.merge_request_unmergeable(merge_request)
        TodoService.new.merge_request_became_unmergeable(merge_request)
      end
    end
    # rubocop: enable CodeReuse/ServiceClass

    def check_state?(merge_status)
      [:unchecked, :cannot_be_merged_recheck].include?(merge_status.to_sym)
    end
  end

  validates :source_project, presence: true, unless: [:allow_broken, :importing?, :closed_without_fork?]
  validates :source_branch, presence: true
  validates :target_project, presence: true
  validates :target_branch, presence: true
  validates :merge_user, presence: true, if: :auto_merge_enabled?, unless: :importing?
  validate :validate_branches, unless: [:allow_broken, :importing?, :closed_without_fork?]
  validate :validate_fork, unless: :closed_without_fork?
  validate :validate_target_project, on: :create

  scope :by_source_or_target_branch, ->(branch_name) do
    where("source_branch = :branch OR target_branch = :branch", branch: branch_name)
  end
  scope :by_milestone, ->(milestone) { where(milestone_id: milestone) }
  scope :of_projects, ->(ids) { where(target_project_id: ids) }
  scope :from_project, ->(project) { where(source_project_id: project.id) }
  scope :from_and_to_forks, ->(project) do
    where('source_project_id <> target_project_id AND (source_project_id = ? OR target_project_id = ?)', project.id, project.id)
  end
  scope :merged, -> { with_state(:merged) }
  scope :closed_and_merged, -> { with_states(:closed, :merged) }
  scope :open_and_closed, -> { with_states(:opened, :closed) }
  scope :from_source_branches, ->(branches) { where(source_branch: branches) }
  scope :by_commit_sha, ->(sha) do
    where('EXISTS (?)', MergeRequestDiff.select(1).where('merge_requests.latest_merge_request_diff_id = merge_request_diffs.id').by_commit_sha(sha)).reorder(nil)
  end
  scope :by_merge_commit_sha, -> (sha) do
    where(merge_commit_sha: sha)
  end
  scope :join_project, -> { joins(:target_project) }
  scope :references_project, -> { references(:target_project) }
  scope :with_api_entity_associations, -> {
    preload(:assignees, :author, :unresolved_notes, :labels, :milestone,
            :timelogs, :latest_merge_request_diff,
            metrics: [:latest_closed_by, :merged_by],
            target_project: [:route, { namespace: :route }],
            source_project: [:route, { namespace: :route }])
  }
  scope :by_target_branch_wildcard, ->(wildcard_branch_name) do
    where("target_branch LIKE ?", ApplicationRecord.sanitize_sql_like(wildcard_branch_name).tr('*', '%'))
  end
  scope :by_target_branch, ->(branch_name) { where(target_branch: branch_name) }
  scope :preload_source_project, -> { preload(:source_project) }

  scope :with_auto_merge_enabled, -> do
    with_state(:opened).where(auto_merge_enabled: true)
  end

  ignore_column :state, remove_with: '12.7', remove_after: '2019-12-22'

  after_save :keep_around_commit, unless: :importing?

  alias_attribute :project, :target_project
  alias_attribute :project_id, :target_project_id

  # Currently, `merge_when_pipeline_succeeds` column is used as a flag
  # to check if _any_ auto merge strategy is activated on the merge request.
  # Today, we have multiple strategies and MWPS is one of them.
  # we'd eventually rename the column for avoiding confusions, but in the mean time
  # please use `auto_merge_enabled` alias instead of `merge_when_pipeline_succeeds`.
  alias_attribute :auto_merge_enabled, :merge_when_pipeline_succeeds
  alias_method :issuing_parent, :target_project

  delegate :active?, to: :head_pipeline, prefix: true, allow_nil: true
  delegate :success?, :active?, to: :actual_head_pipeline, prefix: true, allow_nil: true

  RebaseLockTimeout = Class.new(StandardError)

  REBASE_LOCK_MESSAGE = _("Failed to enqueue the rebase operation, possibly due to a long-lived transaction. Try again later.")

  def self.reference_prefix
    '!'
  end

  # Returns the top 100 target branches
  #
  # The returned value is a Array containing branch names
  # sort by updated_at of merge request:
  #
  #     ['master', 'develop', 'production']
  #
  # limit - The maximum number of target branch to return.
  def self.recent_target_branches(limit: 100)
    group(:target_branch)
      .select(:target_branch)
      .reorder(arel_table[:updated_at].maximum.desc)
      .limit(limit)
      .pluck(:target_branch)
  end

  def rebase_in_progress?
    rebase_jid.present? && Gitlab::SidekiqStatus.running?(rebase_jid)
  end

  # Use this method whenever you need to make sure the head_pipeline is synced with the
  # branch head commit, for example checking if a merge request can be merged.
  # For more information check: https://gitlab.com/gitlab-org/gitlab-foss/issues/40004
  def actual_head_pipeline
    head_pipeline&.matches_sha_or_source_sha?(diff_head_sha) ? head_pipeline : nil
  end

  def merge_pipeline
    return unless merged?

    target_project.pipeline_for(target_branch, merge_commit_sha)
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
    source = unscoped.where(source_project_id: relation)
    target = unscoped.where(target_project_id: relation)

    from_union([source, target])
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

  WIP_REGEX = /\A*(\[WIP\]\s*|WIP:\s*|WIP\s+)+\s*/i.freeze

  def self.work_in_progress?(title)
    !!(title =~ WIP_REGEX)
  end

  def self.wipless_title(title)
    title.sub(WIP_REGEX, "")
  end

  def self.wip_title(title)
    work_in_progress?(title) ? title : "WIP: #{title}"
  end

  def committers
    @committers ||= commits.committers
  end

  # Verifies if title has changed not taking into account WIP prefix
  # for merge requests.
  def wipless_title_changed(old_title)
    self.class.wipless_title(old_title) != self.wipless_title
  end

  def hook_attrs
    Gitlab::HookData::MergeRequestBuilder.new(self).build
  end

  # `from` argument can be a Namespace or Project.
  def to_reference(from = nil, full: false)
    reference = "#{self.class.reference_prefix}#{iid}"

    "#{project.to_reference(from, full: full)}#{reference}"
  end

  def commits(limit: nil)
    return merge_request_diff.commits(limit: limit) if persisted?

    commits_arr = if compare_commits
                    reversed_commits = compare_commits.reverse
                    limit ? reversed_commits.take(limit) : reversed_commits
                  else
                    []
                  end

    CommitCollection.new(source_project, commits_arr, source_branch)
  end

  def recent_commits
    commits(limit: MergeRequestDiff::COMMITS_SAFE_SIZE)
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

  def commit_shas(limit: nil)
    return merge_request_diff.commit_shas(limit: limit) if persisted?

    shas =
      if compare_commits
        compare_commits.to_a.reverse.map(&:sha)
      else
        Array(diff_head_sha)
      end

    limit ? shas.take(limit) : shas
  end

  def supports_suggestion?
    true
  end

  # Calls `MergeWorker` to proceed with the merge process and
  # updates `merge_jid` with the MergeWorker#jid.
  # This helps tracking enqueued and ongoing merge jobs.
  def merge_async(user_id, params)
    jid = MergeWorker.perform_async(id, user_id, params.to_h)
    update_column(:merge_jid, jid)

    # merge_ongoing? depends on merge_jid
    # expire etag cache since the attribute is changed without triggering callbacks
    expire_etag_cache
  end

  # Set off a rebase asynchronously, atomically updating the `rebase_jid` of
  # the MR so that the status of the operation can be tracked.
  def rebase_async(user_id)
    with_rebase_lock do
      raise ActiveRecord::StaleObjectError if !open? || rebase_in_progress?

      # Although there is a race between setting rebase_jid here and clearing it
      # in the RebaseWorker, it can't do any harm since we check both that the
      # attribute is set *and* that the sidekiq job is still running. So a JID
      # for a completed RebaseWorker is equivalent to a nil JID.
      jid = Sidekiq::Worker.skipping_transaction_check do
        RebaseWorker.perform_async(id, user_id)
      end

      update_column(:rebase_jid, jid)
    end

    # rebase_in_progress? depends on rebase_jid
    # expire etag cache since the attribute is changed without triggering callbacks
    expire_etag_cache
  end

  def merge_participants
    participants = [author]

    if auto_merge_enabled? && !participants.include?(merge_user)
      participants << merge_user
    end

    participants
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

  def non_latest_diffs
    merge_request_diffs.where.not(id: merge_request_diff.id)
  end

  # Overwritten in EE
  def note_positions_for_paths(paths, _user = nil)
    positions = notes.new_diff_notes.joins(:note_diff_file)
      .where('note_diff_files.old_path IN (?) OR note_diff_files.new_path IN (?)', paths, paths)
      .positions

    Gitlab::Diff::PositionCollection.new(positions, diff_head_sha)
  end

  def preloads_discussion_diff_highlighting?
    true
  end

  def discussions_diffs
    strong_memoize(:discussions_diffs) do
      note_diff_files = NoteDiffFile
        .joins(:diff_note)
        .merge(notes.or(commit_notes))
        .includes(diff_note: :project)

      Gitlab::DiscussionsDiff::FileCollection.new(note_diff_files.to_a)
    end
  end

  def diff_size
    # Calling `merge_request_diff.diffs.real_size` will also perform
    # highlighting, which we don't need here.
    merge_request_diff&.real_size || diffs.real_size
  end

  def modified_paths(past_merge_request_diff: nil)
    diffs = if past_merge_request_diff
              past_merge_request_diff
            elsif compare
              compare
            else
              self.merge_request_diff
            end

    diffs.modified_paths
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
    if importing? || persisted?
      merge_request_diff.diff_refs
    else
      repository_diff_refs
    end
  end

  # Instead trying to fetch the
  # persisted diff_refs, this method goes
  # straight to the repository to get the
  # most recent data possible.
  def repository_diff_refs
    Gitlab::Diff::DiffRefs.new(
      base_sha:  branch_merge_base_sha,
      start_sha: target_branch_sha,
      head_sha:  source_branch_sha
    )
  end

  def branch_merge_base_sha
    branch_merge_base_commit.try(:sha)
  end

  def validate_branches
    return unless target_project && source_project

    if target_project == source_project && target_branch == source_branch
      errors.add :branch_conflict, "You can't use same project/branch for source and target"
      return
    end

    [:source_branch, :target_branch].each { |attr| validate_branch_name(attr) }

    if opened?
      similar_mrs = target_project
        .merge_requests
        .where(source_branch: source_branch, target_branch: target_branch)
        .where(source_project_id: source_project&.id)
        .opened

      similar_mrs = similar_mrs.where.not(id: id) if persisted?

      conflict = similar_mrs.first

      if conflict.present?
        errors.add(
          :validate_branches,
          "Another open merge request already exists for this source branch: #{conflict.to_reference}"
        )
      end
    end
  end

  def validate_branch_name(attr)
    return unless changes_include?(attr)

    branch = read_attribute(attr)

    return unless branch

    errors.add(attr) unless Gitlab::GitRefValidator.validate_merge_request_branch(branch)
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

  def reopenable?
    closed? && !source_project_missing? && source_branch_exists?
  end

  def ensure_merge_request_diff
    merge_request_diff || create_merge_request_diff
  end

  def create_merge_request_diff
    fetch_ref!

    # n+1: https://gitlab.com/gitlab-org/gitlab-foss/issues/37435
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      merge_request_diffs.create!
      reload_merge_request_diff
    end
  end

  def viewable_diffs
    @viewable_diffs ||= merge_request_diffs.viewable.to_a
  end

  def merge_request_diff_for(diff_refs_or_sha)
    matcher =
      if diff_refs_or_sha.is_a?(Gitlab::Diff::DiffRefs)
        {
          'start_commit_sha' => diff_refs_or_sha.start_sha,
          'head_commit_sha' => diff_refs_or_sha.head_sha,
          'base_commit_sha' => diff_refs_or_sha.base_sha
        }
      else
        { 'head_commit_sha' => diff_refs_or_sha }
      end

    viewable_diffs.find do |diff|
      diff.attributes.slice(*matcher.keys) == matcher
    end
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
    if (saved_change_to_source_branch? || saved_change_to_target_branch?) &&
        (source_branch_head && target_branch_head)
      reload_diff
    end
  end

  # rubocop: disable CodeReuse/ServiceClass
  def reload_diff(current_user = nil)
    return unless open?

    MergeRequests::ReloadDiffsService.new(self, current_user).execute
  end

  def check_mergeability
    return if Feature.enabled?(:merge_requests_conditional_mergeability_check, default_enabled: true) && !recheck_merge_status?

    MergeRequests::MergeabilityCheckService.new(self).execute(retry_lease: false)
  end
  # rubocop: enable CodeReuse/ServiceClass

  # Returns boolean indicating the merge_status should be rechecked in order to
  # switch to either can_be_merged or cannot_be_merged.
  def recheck_merge_status?
    self.class.state_machines[:merge_status].check_state?(merge_status)
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

    check_mergeability

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

  def can_cancel_auto_merge?(current_user)
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

  def auto_merge_strategy
    return unless auto_merge_enabled?

    merge_params['auto_merge_strategy'] || AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS
  end

  def auto_merge_strategy=(strategy)
    merge_params['auto_merge_strategy'] = strategy
  end

  def remove_source_branch?
    should_remove_source_branch? || force_remove_source_branch?
  end

  def notify_conflict?
    (opened? || locked?) &&
      has_commits? &&
      !branch_missing? &&
      !project.repository.can_be_merged?(diff_head_sha, target_branch)
  rescue Gitlab::Git::CommandError
    # Checking mergeability can trigger exception, e.g. non-utf8
    # We ignore this type of errors.
    false
  end

  def related_notes
    # We're using a UNION ALL here since this results in better performance
    # compared to using OR statements. We're using UNION ALL since the queries
    # used won't produce any duplicates (e.g. a note for a commit can't also be
    # a note for an MR).
    Note
      .from_union([notes, commit_notes], remove_duplicates: false)
      .includes(:noteable)
  end

  alias_method :discussion_notes, :related_notes

  def commit_notes
    # Fetch comments only from last 100 commits
    commit_ids = commit_shas(limit: 100)

    Note
      .user
      .where(project_id: [source_project_id, target_project_id])
      .for_commit_id(commit_ids)
  end

  def mergeable_discussions_state?
    return true unless project.only_allow_merge_if_all_discussions_are_resolved?

    unresolved_notes.none?(&:to_be_resolved?)
  end

  def for_fork?
    target_project != source_project
  end

  # If the merge request closes any issues, save this information in the
  # `MergeRequestsClosingIssues` model. This is a performance optimization.
  # Calculating this information for a number of merge requests requires
  # running `ReferenceExtractor` on each of them separately.
  # This optimization does not apply to issues from external sources.
  def cache_merge_request_closes_issues!(current_user = self.author)
    return unless project.issues_enabled?
    return if closed? || merged?

    transaction do
      self.merge_requests_closing_issues.delete_all

      closes_issues(current_user).each do |issue|
        next if issue.is_a?(ExternalIssue)

        self.merge_requests_closing_issues.create!(issue: issue)
      end
    end
  end

  def visible_closing_issues_for(current_user = self.author)
    strong_memoize(:visible_closing_issues_for) do
      if self.target_project.has_external_issue_tracker?
        closes_issues(current_user)
      else
        cached_closes_issues.select do |issue|
          Ability.allowed?(current_user, :read_issue, issue)
        end
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

    ext.issues - visible_closing_issues_for(current_user)
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

  def default_merge_commit_message(include_description: false)
    closes_issues_references = visible_closing_issues_for.map do |issue|
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

  # Returns the oldest multi-line commit message, or the MR title if none found
  def default_squash_commit_message
    strong_memoize(:default_squash_commit_message) do
      recent_commits.without_merge_commits.reverse_each.find(&:description?)&.safe_message || title
    end
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
    return false unless actual_head_pipeline

    actual_head_pipeline.success?
  end

  def environments_for(current_user, latest: false)
    return [] unless diff_head_commit

    envs = EnvironmentsFinder.new(target_project, current_user,
      ref: target_branch, commit: diff_head_commit, with_tags: true, find_latest: latest).execute

    if source_project
      envs.concat EnvironmentsFinder.new(source_project, current_user,
        ref: source_branch, commit: diff_head_commit, find_latest: latest).execute
    end

    envs.uniq
  end

  ##
  # This method is for looking for active environments which created via pipelines for merge requests.
  # Since deployments run on a merge request ref (e.g. `refs/merge-requests/:iid/head`),
  # we cannot look up environments with source branch name.
  def environments
    return Environment.none unless actual_head_pipeline&.triggered_by_merge_request?

    actual_head_pipeline.environments
  end

  def fetch_ref!
    target_project.repository.fetch_source_branch!(source_project.repository, source_branch, ref_path)
  end

  # Returns the current merge-ref HEAD commit.
  #
  def merge_ref_head
    project.repository.commit(merge_ref_path)
  end

  def ref_path
    "refs/#{Repository::REF_MERGE_REQUEST}/#{iid}/head"
  end

  def merge_ref_path
    "refs/#{Repository::REF_MERGE_REQUEST}/#{iid}/merge"
  end

  def train_ref_path
    "refs/#{Repository::REF_MERGE_REQUEST}/#{iid}/train"
  end

  def cleanup_refs(only: :all)
    target_refs = []
    target_refs << ref_path       if %i[all head].include?(only)
    target_refs << merge_ref_path if %i[all merge].include?(only)
    target_refs << train_ref_path if %i[all train].include?(only)

    project.repository.delete_refs(*target_refs)
  end

  def self.merge_request_ref?(ref)
    ref.start_with?("refs/#{Repository::REF_MERGE_REQUEST}/")
  end

  def self.merge_train_ref?(ref)
    %r{\Arefs/#{Repository::REF_MERGE_REQUEST}/\d+/train\z}.match?(ref)
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
    strong_memoize(:all_pipelines) do
      MergeRequest::Pipelines.new(self).all
    end
  end

  def update_head_pipeline
    find_actual_head_pipeline.try do |pipeline|
      self.head_pipeline = pipeline
      update_column(:head_pipeline_id, head_pipeline.id) if head_pipeline_id_changed?
    end
  end

  def has_test_reports?
    actual_head_pipeline&.has_reports?(Ci::JobArtifact.test_reports)
  end

  def predefined_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: 'CI_MERGE_REQUEST_ID', value: id.to_s)
      variables.append(key: 'CI_MERGE_REQUEST_IID', value: iid.to_s)
      variables.append(key: 'CI_MERGE_REQUEST_REF_PATH', value: ref_path.to_s)
      variables.append(key: 'CI_MERGE_REQUEST_PROJECT_ID', value: project.id.to_s)
      variables.append(key: 'CI_MERGE_REQUEST_PROJECT_PATH', value: project.full_path)
      variables.append(key: 'CI_MERGE_REQUEST_PROJECT_URL', value: project.web_url)
      variables.append(key: 'CI_MERGE_REQUEST_TARGET_BRANCH_NAME', value: target_branch.to_s)
      variables.append(key: 'CI_MERGE_REQUEST_TITLE', value: title)
      variables.append(key: 'CI_MERGE_REQUEST_ASSIGNEES', value: assignee_username_list) if assignees.any?
      variables.append(key: 'CI_MERGE_REQUEST_MILESTONE', value: milestone.title) if milestone
      variables.append(key: 'CI_MERGE_REQUEST_LABELS', value: label_names.join(',')) if labels.present?
      variables.concat(source_project_variables)
    end
  end

  def compare_test_reports
    unless has_test_reports?
      return { status: :error, status_reason: 'This merge request does not have test reports' }
    end

    compare_reports(Ci::CompareTestReportsService)
  end

  def has_exposed_artifacts?
    return false unless Feature.enabled?(:ci_expose_arbitrary_artifacts_in_mr, default_enabled: true)

    actual_head_pipeline&.has_exposed_artifacts?
  end

  # TODO: this method and compare_test_reports use the same
  # result type, which is handled by the controller's #reports_response.
  # we should minimize mistakes by isolating the common parts.
  # issue: https://gitlab.com/gitlab-org/gitlab/issues/34224
  def find_exposed_artifacts
    unless has_exposed_artifacts?
      return { status: :error, status_reason: 'This merge request does not have exposed artifacts' }
    end

    compare_reports(Ci::GenerateExposedArtifactsReportService)
  end

  # TODO: consider renaming this as with exposed artifacts we generate reports,
  # not always compare
  # issue: https://gitlab.com/gitlab-org/gitlab/issues/34224
  def compare_reports(service_class, current_user = nil)
    with_reactive_cache(service_class.name, current_user&.id) do |data|
      unless service_class.new(project, current_user)
        .latest?(base_pipeline, actual_head_pipeline, data)
        raise InvalidateReactiveCache
      end

      data
    end || { status: :parsing }
  end

  def calculate_reactive_cache(identifier, current_user_id = nil, *args)
    service_class = identifier.constantize

    # TODO: the type check should change to something that includes exposed artifacts service
    # issue: https://gitlab.com/gitlab-org/gitlab/issues/34224
    raise NameError, service_class unless service_class < Ci::CompareReportsBaseService

    current_user = User.find_by(id: current_user_id)
    service_class.new(project, current_user).execute(base_pipeline, actual_head_pipeline)
  end

  def all_commits
    MergeRequestDiffCommit
      .where(merge_request_diff: merge_request_diffs.recent)
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

  def short_merge_commit_sha
    Commit.truncate_sha(merge_commit_sha) if merge_commit_sha
  end

  def can_be_reverted?(current_user)
    return false unless merge_commit
    return false unless merged_at

    # It is not guaranteed that Note#created_at will be strictly later than
    # MergeRequestMetric#merged_at. Nanoseconds on MySQL may break this
    # comparison, as will a HA environment if clocks are not *precisely*
    # synchronized. Add a minute's leeway to compensate for both possibilities
    cutoff = merged_at - 1.minute

    notes_association = notes_with_associations.where('created_at >= ?', cutoff)

    !merge_commit.has_been_reverted?(current_user, notes_association)
  end

  def merged_at
    strong_memoize(:merged_at) do
      next unless merged?

      metrics&.merged_at ||
        merge_event&.created_at ||
        notes.system.reorder(nil).find_by(note: 'merged')&.created_at
    end
  end

  def can_be_cherry_picked?
    merge_commit.present?
  end

  def has_complete_diff_refs?
    diff_refs && diff_refs.complete?
  end

  # rubocop: disable CodeReuse/ServiceClass
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
  # rubocop: enable CodeReuse/ServiceClass

  def keep_around_commit
    project.repository.keep_around(self.merge_commit_sha)
  end

  def has_commits?
    merge_request_diff && commits_count.to_i > 0
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

  def pipeline_coverage_delta
    if base_pipeline&.coverage && head_pipeline&.coverage
      '%.2f' % (head_pipeline.coverage.to_f - base_pipeline.coverage.to_f)
    end
  end

  def base_pipeline
    @base_pipeline ||= project.ci_pipelines
      .order(id: :desc)
      .find_by(sha: diff_base_sha, ref: target_branch)
  end

  def discussions_rendered_on_frontend?
    true
  end

  # rubocop: disable CodeReuse/ServiceClass
  def update_project_counter_caches
    Projects::OpenMergeRequestsCountService.new(target_project).refresh_cache
  end
  # rubocop: enable CodeReuse/ServiceClass

  def first_contribution?
    return false if project.team.max_member_access(author_id) > Gitlab::Access::GUEST

    project.merge_requests.merged.where(author_id: author_id).empty?
  end

  # TODO: remove once production database rename completes
  # https://gitlab.com/gitlab-org/gitlab-foss/issues/47592
  alias_attribute :allow_collaboration, :allow_maintainer_to_push

  def allow_collaboration
    collaborative_push_possible? && allow_maintainer_to_push
  end

  alias_method :allow_collaboration?, :allow_collaboration

  def collaborative_push_possible?
    source_project.present? && for_fork? &&
      target_project.visibility_level > Gitlab::VisibilityLevel::PRIVATE &&
      source_project.visibility_level > Gitlab::VisibilityLevel::PRIVATE &&
      !ProtectedBranch.protected?(source_project, source_branch)
  end

  def can_allow_collaboration?(user)
    collaborative_push_possible? &&
      Ability.allowed?(user, :push_code, source_project)
  end

  def squash_in_progress?
    # The source project can be deleted
    return false unless source_project

    source_project.repository.squash_in_progress?(id)
  end

  def find_actual_head_pipeline
    all_pipelines.for_sha_or_source_sha(diff_head_sha).first
  end

  def etag_caching_enabled?
    true
  end

  def recent_visible_deployments
    deployments.visible.includes(:environment).order(id: :desc).limit(10)
  end

  private

  def with_rebase_lock
    if Feature.enabled?(:merge_request_rebase_nowait_lock, default_enabled: true)
      with_retried_nowait_lock { yield }
    else
      with_lock(true) { yield }
    end
  end

  # If the merge request is idle in transaction or has a SELECT FOR
  # UPDATE, we don't want to block indefinitely or this could cause a
  # queue of SELECT FOR UPDATE calls. Instead, try to get the lock for
  # 5 s before raising an error to the user.
  def with_retried_nowait_lock
    # Try at most 0.25 + (1.5 * .25) + (1.5^2 * .25) ... (1.5^5 * .25) = 5.2 s to get the lock
    Retriable.retriable(on: ActiveRecord::LockWaitTimeout, tries: 6, base_interval: 0.25) do
      with_lock('FOR UPDATE NOWAIT') do
        yield
      end
    end
  rescue ActiveRecord::LockWaitTimeout => e
    Gitlab::ErrorTracking.track_exception(e)
    raise RebaseLockTimeout, REBASE_LOCK_MESSAGE
  end

  def source_project_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      break variables unless source_project

      variables.append(key: 'CI_MERGE_REQUEST_SOURCE_PROJECT_ID', value: source_project.id.to_s)
      variables.append(key: 'CI_MERGE_REQUEST_SOURCE_PROJECT_PATH', value: source_project.full_path)
      variables.append(key: 'CI_MERGE_REQUEST_SOURCE_PROJECT_URL', value: source_project.web_url)
      variables.append(key: 'CI_MERGE_REQUEST_SOURCE_BRANCH_NAME', value: source_branch.to_s)
    end
  end

  def expire_etag_cache
    return unless project.namespace

    key = Gitlab::Routing.url_helpers.cached_widget_project_json_merge_request_path(project, self, format: :json)
    Gitlab::EtagCaching::Store.new.touch(key)
  end
end

MergeRequest.prepend_if_ee('::EE::MergeRequest')
