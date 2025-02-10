# frozen_string_literal: true

class MergeRequest < ApplicationRecord
  extend Gitlab::Cache::RequestCache

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
  include MilestoneEventable
  include StateEventable
  include Approvable
  include IdInOrdered
  include Todoable
  include Spammable

  extend ::Gitlab::Utils::Override

  sha_attribute :squash_commit_sha
  sha_attribute :merge_ref_sha

  self.reactive_cache_key = ->(model) { [model.project.id, model.iid] }
  self.reactive_cache_refresh_interval = 10.minutes
  self.reactive_cache_lifetime = 10.minutes
  self.reactive_cache_work_type = :no_dependency

  SORTING_PREFERENCE_FIELD = :merge_requests_sort
  CI_MERGE_REQUEST_DESCRIPTION_MAX_LENGTH = 2700
  MERGE_LEASE_TIMEOUT = 15.minutes.to_i

  belongs_to :target_project, class_name: "Project"
  belongs_to :source_project, class_name: "Project"
  belongs_to :merge_user, class_name: "User"

  has_internal_id :iid, scope: :target_project, track_if: -> { !importing? },
    init: ->(mr, scope) do
      if mr
        mr.target_project&.merge_requests&.maximum(:iid)
      elsif scope[:project]
        where(target_project: scope[:project]).maximum(:iid)
      end
    end

  has_many :merge_request_diffs,
    -> { regular }, inverse_of: :merge_request
  has_many :merge_request_context_commits, inverse_of: :merge_request
  has_many :merge_request_context_commit_diff_files, through: :merge_request_context_commits, source: :diff_files

  has_one :merge_request_diff,
    -> { regular.order('merge_request_diffs.id DESC') }, inverse_of: :merge_request
  has_one :merge_head_diff,
    -> { merge_head }, inverse_of: :merge_request, class_name: 'MergeRequestDiff'
  has_one :cleanup_schedule, inverse_of: :merge_request
  has_one :predictions, inverse_of: :merge_request
  delegate :suggested_reviewers, to: :predictions

  has_one :merge_schedule, class_name: 'MergeRequests::MergeSchedule', inverse_of: :merge_request
  has_one :metrics, inverse_of: :merge_request, autosave: true

  belongs_to :latest_merge_request_diff, class_name: 'MergeRequestDiff'
  manual_inverse_association :latest_merge_request_diff, :merge_request

  # method overridden in EE
  def suggested_reviewer_users
    User.none
  end

  # This is the same as latest_merge_request_diff unless:
  # 1. There are arguments - in which case we might be trying to force-reload.
  # 2. This association is already loaded.
  # 3. The latest diff does not exist.
  # 4. It doesn't have any merge_request_diffs - it returns an empty MergeRequestDiff
  #
  # The second one in particular is important - MergeRequestDiff#merge_request
  # is the inverse of MergeRequest#merge_request_diff, which means it may not be
  # the latest diff, because we could have loaded any diff from this particular
  # MR. If we haven't already loaded a diff, then it's fine to load the latest.
  def merge_request_diff
    fallback = latest_merge_request_diff unless association(:merge_request_diff).loaded?

    fallback || super || MergeRequestDiff.new(merge_request_id: id)
  end

  belongs_to :head_pipeline, class_name: "Ci::Pipeline", inverse_of: :merge_requests_as_head_pipeline

  has_many :events, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  has_many :merge_requests_closing_issues,
    class_name: 'MergeRequestsClosingIssues',
    inverse_of: :merge_request,
    dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  has_many :cached_closes_issues, through: :merge_requests_closing_issues, source: :issue
  has_many :pipelines_for_merge_request, foreign_key: 'merge_request_id', class_name: 'Ci::Pipeline', inverse_of: :merge_request
  has_many :suggestions, through: :notes
  has_many :unresolved_notes, -> { unresolved }, as: :noteable, class_name: 'Note', inverse_of: :noteable

  has_many :merge_request_assignees
  has_many :assignees, class_name: "User", through: :merge_request_assignees
  has_many :merge_request_reviewers
  has_many :reviewers, class_name: "User", through: :merge_request_reviewers
  has_many :user_mentions, class_name: "MergeRequestUserMention", dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  has_many :deployment_merge_requests

  # These are deployments created after the merge request has been merged, and
  # the merge request was tracked explicitly (instead of implicitly using a CI
  # build).
  has_many :deployments,
    through: :deployment_merge_requests

  has_many :draft_notes
  has_many :reviews, inverse_of: :merge_request
  has_many :reviewed_by_users, -> { distinct }, through: :reviews, source: :author
  has_many :created_environments, class_name: 'Environment', foreign_key: :merge_request_id, inverse_of: :merge_request
  has_many :assignment_events, class_name: 'ResourceEvents::MergeRequestAssignmentEvent', inverse_of: :merge_request

  KNOWN_MERGE_PARAMS = [
    :auto_merge_strategy,
    :should_remove_source_branch,
    :force_remove_source_branch,
    :commit_message,
    :squash_commit_message,
    :sha,
    :skip_ci
  ].freeze
  serialize :merge_params, Hash # rubocop:disable Cop/ActiveRecordSerialize

  before_validation :set_draft_status

  after_create :ensure_merge_request_diff, unless: :skip_ensure_merge_request_diff
  after_update :clear_memoized_shas
  after_update :reload_diff_if_branch_changed
  after_save :keep_around_commit, unless: :importing?
  after_commit :ensure_metrics!, on: [:create, :update], unless: :importing?
  after_commit :expire_etag_cache, unless: :importing?

  # When this attribute is true some MR validation is ignored
  # It allows us to close or modify broken merge requests
  attr_accessor :allow_broken

  # Temporary flag to skip merge_request_diff creation on create.
  # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/100390
  attr_accessor :skip_ensure_merge_request_diff

  # Temporary fields to store compare vars
  # when creating new merge request
  attr_accessor :can_be_created, :compare_commits, :diff_options, :compare

  # Flag to skip triggering mergeRequestMergeStatusUpdated GraphQL subscription.
  attr_accessor :skip_merge_status_trigger

  attr_spammable :title, spam_title: true
  attr_spammable :description, spam_description: true

  participant :reviewers

  # Keep states definition to be evaluated before the state_machine block to
  #   avoid spec failures. If this gets evaluated after, the `merged` and `locked`
  #   states (which are overridden) can be nil.
  #
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

    before_transition any => [:opened, :merged] do |merge_request|
      merge_request.merge_jid = nil
    end

    before_transition any => :closed do |merge_request|
      merge_request.merge_error = nil
    end

    before_transition any => :merged do |merge_request|
      merge_request.merge_error = nil
      merge_request.metrics.first_contribution = true if merge_request.first_contribution?
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

  state_machine :merge_status, initial: :unchecked do
    event :mark_as_preparing do
      transition unchecked: :preparing
    end

    event :mark_as_unchecked do
      transition [:preparing, :can_be_merged, :checking] => :unchecked
      transition [:cannot_be_merged, :cannot_be_merged_rechecking] => :cannot_be_merged_recheck
    end

    event :mark_as_checking do
      transition unchecked: :checking
      transition cannot_be_merged_recheck: :cannot_be_merged_rechecking
    end

    event :mark_as_mergeable do
      transition [:unchecked, :cannot_be_merged_recheck, :checking, :cannot_be_merged_rechecking] => :can_be_merged
    end

    event :mark_as_unmergeable do
      transition [:unchecked, :cannot_be_merged_recheck, :checking, :cannot_be_merged_rechecking] => :cannot_be_merged
    end

    state :preparing
    state :unchecked
    state :cannot_be_merged_recheck
    state :checking
    state :cannot_be_merged_rechecking
    state :can_be_merged
    state :cannot_be_merged

    around_transition do |merge_request, transition, block|
      Gitlab::Timeless.timeless(merge_request, &block)
    end

    after_transition any => [:unchecked, :cannot_be_merged_recheck, :can_be_merged, :cannot_be_merged] do |merge_request, transition|
      next if merge_request.skip_merge_status_trigger

      merge_request.run_after_commit do
        GraphqlTriggers.merge_request_merge_status_updated(merge_request)
      end
    end

    # rubocop: disable CodeReuse/ServiceClass
    after_transition [:unchecked, :checking] => :cannot_be_merged do |merge_request, transition|
      if merge_request.notify_conflict?
        merge_request.run_after_commit do
          NotificationService.new.merge_request_unmergeable(merge_request)
        end

        TodoService.new.merge_request_became_unmergeable(merge_request)
      end
    end
    # rubocop: enable CodeReuse/ServiceClass

    def check_state?(merge_status)
      [:unchecked, :cannot_be_merged_recheck, :checking, :cannot_be_merged_rechecking].include?(merge_status.to_sym)
    end

    # rubocop: disable Style/SymbolProc
    before_transition { |merge_request| merge_request.enable_transitioning }

    after_transition { |merge_request| merge_request.disable_transitioning }
    # rubocop: enable Style/SymbolProc
  end

  # Returns current merge_status except it returns `cannot_be_merged_rechecking` as `checking`
  # to avoid exposing unnecessary internal state
  def public_merge_status
    cannot_be_merged_rechecking? || preparing? ? 'checking' : merge_status
  end

  validates :source_project, presence: true, unless: [:allow_broken, :importing?, :closed_or_merged_without_fork?]
  validates :source_branch, presence: true
  validates :target_project, presence: true
  validates :target_branch, presence: true
  validates :merge_user, presence: true, if: :auto_merge_enabled?, unless: :importing?
  validate :validate_branches, unless: [
    :allow_broken,
    :importing_or_transitioning?,
    :closed_or_merged_without_fork?
  ]
  validate :validate_fork, unless: :closed_or_merged_without_fork?
  validate :validate_target_project, on: :create, unless: :importing_or_transitioning?
  validate :validate_reviewer_size_length, unless: :importing_or_transitioning?

  scope :by_source_or_target_branch, ->(branch_name) do
    where("source_branch = :branch OR target_branch = :branch", branch: branch_name)
  end
  scope :by_milestone, ->(milestone) { where(milestone_id: milestone) }
  scope :of_projects, ->(ids) { where(target_project_id: ids) }
  scope :from_project, ->(project) { where(source_project_id: project.id) }
  scope :from_fork, -> { where('source_project_id <> target_project_id') }
  scope :from_and_to_forks, ->(project) do
    from_fork.where('source_project_id = ? OR target_project_id = ?', project.id, project.id)
  end
  scope :merged, -> { with_state(:merged) }
  scope :open_and_closed, -> { with_state(:opened, :closed) }
  scope :drafts, -> { where(draft: true) }
  scope :from_source_branches, ->(branches) { where(source_branch: branches) }
  scope :by_sorted_source_branches, ->(branches) do
    from_source_branches(branches)
      .order(source_branch: :asc, id: :desc)
  end
  scope :including_target_project, -> do
    includes(:target_project)
  end
  scope :by_commit_sha, ->(sha) do
    where('EXISTS (?)', MergeRequestDiff.select(1).where('merge_requests.latest_merge_request_diff_id = merge_request_diffs.id').by_commit_sha(sha)).reorder(nil)
  end
  scope :by_merge_commit_sha, ->(sha) do
    where(merge_commit_sha: sha)
  end
  scope :by_squash_commit_sha, ->(sha) do
    where(squash_commit_sha: sha)
  end
  scope :by_merged_commit_sha, ->(sha) do
    where(merged_commit_sha: sha)
  end
  scope :by_merged_or_merge_or_squash_commit_sha, ->(sha) do
    from_union([by_squash_commit_sha(sha), by_merge_commit_sha(sha), by_merged_commit_sha(sha)])
  end
  scope :by_related_commit_sha, ->(sha) do
    from_union(
      [
        by_commit_sha(sha),
        by_squash_commit_sha(sha),
        by_merge_commit_sha(sha),
        by_merged_commit_sha(sha)
      ]
    )
  end
  scope :by_latest_merge_request_diffs, ->(merge_request_diffs) do
    where(latest_merge_request_diff_id: merge_request_diffs)
  end
  scope :join_project, -> { joins(:target_project) }
  scope :join_metrics, ->(target_project_id = nil) do
    # Do not join the relation twice
    return self if self.arel.join_sources.any? { |join| join.left.try(:name).eql?(MergeRequest::Metrics.table_name) }

    query = joins(:metrics)

    if !target_project_id && self.where_values_hash["target_project_id"]
      target_project_id = self.where_values_hash["target_project_id"]
      query = query.unscope(where: :target_project_id)
    end

    project_condition = if target_project_id
                          MergeRequest::Metrics.arel_table[:target_project_id].eq(target_project_id)
                        else
                          MergeRequest.arel_table[:target_project_id].eq(MergeRequest::Metrics.arel_table[:target_project_id])
                        end

    query.where(project_condition)
  end
  scope :references_project, -> { references(:target_project) }
  scope :with_api_entity_associations, -> {
    preload_routables.preload(
      :assignees, :author, :unresolved_notes, :labels, :milestone,
      :timelogs, :latest_merge_request_diff, :reviewers,
      :merge_schedule,
      target_project: [:project_feature, :project_setting],
      metrics: [:latest_closed_by, :merged_by]
    )
  }

  scope :with_csv_entity_associations, -> { preload(:assignees, :approved_by_users, :author, :milestone, metrics: [:merged_by]) }
  scope :recently_unprepared, -> { where(prepared_at: nil).where(created_at: 2.hours.ago..).order(:created_at, :id) } # id is the tie-breaker

  scope :by_target_branch_wildcard, ->(wildcard_branch_name) do
    where("target_branch LIKE ?", ApplicationRecord.sanitize_sql_like(wildcard_branch_name).tr('*', '%'))
  end
  scope :by_target_branch, ->(branch_name) { where(target_branch: branch_name) }
  scope :order_by_metric, ->(metric, direction) do
    order = order_by_metric_column(metric, direction)
    order.apply_cursor_conditions(join_metrics).order(order)
  end
  scope :reorder_by_metric, ->(metric, direction) do
    order = order_by_metric_column(metric, direction)
    order.apply_cursor_conditions(join_metrics).reorder(order)
  end

  scope :order_merged_at_asc, -> { order_by_metric(:merged_at, 'ASC') }
  scope :order_merged_at_desc, -> { order_by_metric(:merged_at, 'DESC') }
  scope :order_closed_at_asc, -> { order_by_metric(:latest_closed_at, 'ASC') }
  scope :order_closed_at_desc, -> { order_by_metric(:latest_closed_at, 'DESC') }
  scope :preload_source_project, -> { preload(:source_project) }
  scope :preload_target_project, -> { preload(:target_project) }
  scope :preload_target_project_with_namespace, -> { preload(target_project: [:namespace]) }
  scope :preload_routables, -> do
    preload(
      target_project: [:route, { namespace: :route }],
      source_project: [:route, { namespace: :route }]
    )
  end
  scope :preload_author, -> { preload(:author) }
  scope :preload_approved_by_users, -> { preload(:approved_by_users) }
  scope :preload_metrics, ->(relation) { preload(metrics: relation) }
  scope :preload_project_and_latest_diff, -> { preload(:source_project, :latest_merge_request_diff) }
  scope :preload_latest_diff_commit, -> { preload(latest_merge_request_diff: { merge_request_diff_commits: [:commit_author, :committer] }) }
  scope :preload_milestoneish_associations, -> { preload_routables.preload(:assignees, :labels) }

  scope :with_web_entity_associations, -> do
    preload(:author, :labels, target_project: [:project_feature, { group: [:route, :parent], namespace: :route }])
  end

  scope :with_auto_merge_enabled, -> do
    with_state(:opened).where(auto_merge_enabled: true)
  end

  scope :including_metrics, -> do
    includes(:metrics)
  end

  scope :with_jira_issue_keys, -> { where('title ~ :regex OR merge_requests.description ~ :regex', regex: Gitlab::Regex.jira_issue_key_regex(expression_escape: '\m').source) }

  scope :review_requested, -> do
    where(reviewers_subquery.exists)
  end

  scope :no_review_requested, -> do
    where(reviewers_subquery.exists.not)
  end

  scope :review_requested_to, ->(user, states = nil) do
    scope = reviewers_subquery.where(Arel::Table.new("#{to_ability_name}_reviewers")[:user_id].eq(user.id))
    scope = scope.where(Arel::Table.new("#{to_ability_name}_reviewers")[:state].in(states)) if states

    where(scope.exists)
  end

  scope :no_review_requested_to, ->(user) do
    where(
      reviewers_subquery
        .where(Arel::Table.new("#{to_ability_name}_reviewers")[:user_id].eq(user.id))
        .exists
        .not
    )
  end

  scope :review_states, ->(states) do
    where(
      reviewers_subquery
        .where(Arel::Table.new("#{to_ability_name}_reviewers")[:state].in(states))
        .exists
    )
  end

  scope :no_review_states, ->(states) do
    where(
      reviewers_subquery.exists
    )
    .where(
      reviewers_subquery
        .where(Arel::Table.new("#{to_ability_name}_reviewers")[:state].in(states))
        .exists
        .not
    )
  end

  scope :assignee_or_reviewer, ->(user, assigned_review_states, reviewer_state) do
    assigned_to_scope = assigned_to(user)
    assigned_to_scope = assigned_to_scope.review_states(assigned_review_states) if assigned_review_states

    from_union(
      assigned_to_scope,
      review_requested_to(user, reviewer_state)
    )
  end

  scope :without_hidden, -> {
    if Feature.enabled?(:hide_merge_requests_from_banned_users)
      where_not_exists(Users::BannedUser.where('merge_requests.author_id = banned_users.user_id'))
    else
      all
    end
  }

  scope :merged_without_state_event_source, -> {
    joins(:resource_state_events)
    .merge(ResourceStateEvent.merged_with_no_event_source)
  }

  scope :by_blob_path, ->(path) do
    joins(latest_merge_request_diff: :merge_request_diff_files)
      .where(merge_request_diff_files: { old_path: path })
  end

  def self.total_time_to_merge
    join_metrics
      .where(
        # Replicating the scope MergeRequest::Metrics.with_valid_time_to_merge
        MergeRequest::Metrics.arel_table[:merged_at].gt(
          MergeRequest::Metrics.arel_table[:created_at]
        )
      )
      .pick(MergeRequest::Metrics.time_to_merge_expression)
  end

  alias_attribute :project, :target_project
  alias_attribute :project_id, :target_project_id

  # Currently, `merge_when_pipeline_succeeds` column is used as a flag
  # to check if _any_ auto merge strategy is activated on the merge request.
  # Today, we have multiple strategies and MWPS is one of them.
  # we'd eventually rename the column for avoiding confusions, but in the mean time
  # please use `auto_merge_enabled` alias instead of `merge_when_pipeline_succeeds`.
  alias_attribute :auto_merge_enabled, :merge_when_pipeline_succeeds
  alias_attribute :issuing_parent_id, :target_project_id
  alias_method :issuing_parent, :target_project

  delegate :builds_with_coverage, to: :head_pipeline, prefix: true, allow_nil: true

  RebaseLockTimeout = Class.new(StandardError)

  def self.reference_prefix
    '!'
  end

  def self.order_by_metric_column(metric, direction)
    column_expression = MergeRequest::Metrics.arel_table[metric]
    column_expression_with_direction = direction == 'ASC' ? column_expression.asc : column_expression.desc

    Gitlab::Pagination::Keyset::Order.build(
      [
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: "merge_request_metrics_#{metric}",
          column_expression: column_expression,
          order_expression: column_expression_with_direction.nulls_last,
          reversed_order_expression: column_expression_with_direction.reverse.nulls_first,
          order_direction: direction,
          nullable: :nulls_last,
          add_to_projections: true
        ),
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'merge_request_metrics_id',
          order_expression: MergeRequest::Metrics.arel_table[:id].desc,
          add_to_projections: true
        )
      ])
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

  def self.recent_source_branches(limit: 100)
    group(:source_branch)
      .select(:source_branch)
      .reorder(arel_table[:updated_at].maximum.desc)
      .limit(limit)
      .pluck(:source_branch)
  end

  def self.sort_by_attribute(method, excluded_labels: [])
    case method.to_s
    when 'merged_at', 'merged_at_asc' then order_merged_at_asc
    when 'closed_at', 'closed_at_asc' then order_closed_at_asc
    when 'merged_at_desc' then order_merged_at_desc
    when 'closed_at_desc' then order_closed_at_desc
    else
      super
    end
  end

  def self.reviewers_subquery
    MergeRequestReviewer.arel_table
      .project('true')
      .where(Arel::Nodes::SqlLiteral.new("#{to_ability_name}_id = #{to_ability_name}s.id"))
  end

  def rebase_in_progress?
    rebase_jid.present? && Gitlab::SidekiqStatus.running?(rebase_jid)
  end

  def permits_force_push?
    return true unless ProtectedBranch.protected?(source_project, source_branch)

    ProtectedBranch.allow_force_push?(source_project, source_branch)
  end

  # Use this method whenever you need to make sure the head_pipeline is synced with the
  # branch head commit, for example checking if a merge request can be merged.
  # For more information check: https://gitlab.com/gitlab-org/gitlab-foss/issues/40004
  def diff_head_pipeline
    head_pipeline&.matches_sha_or_source_sha?(diff_head_sha) ? head_pipeline : nil
  end

  def merge_pipeline
    if sha = merged_commit_sha
      target_project.latest_pipeline(target_branch, sha)
    end
  end

  def head_pipeline_active?
    !!head_pipeline&.active?
  end

  def diff_head_pipeline_active?
    !!diff_head_pipeline&.active?
  end

  def diff_head_pipeline_success?
    !!diff_head_pipeline&.success?
  end

  # Pattern used to extract `!123` merge request references from text
  #
  # This pattern supports cross-project references.
  def self.reference_pattern
    @reference_pattern ||= %r{
      (#{Project.reference_pattern})?
      #{Regexp.escape(reference_prefix)}#{Gitlab::Regex.merge_request}
    }x
  end

  def self.link_reference_pattern
    @link_reference_pattern ||= compose_link_reference_pattern('merge_requests', Gitlab::Regex.merge_request)
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
  #
  # Only set `regular` merge request diffs as latest so `merge_head` diff
  # won't be considered as `MergeRequest#merge_request_diff`.
  def self.set_latest_merge_request_diff_ids!
    update = "
      latest_merge_request_diff_id = (
        SELECT MAX(id)
        FROM merge_request_diffs
        WHERE merge_requests.id = merge_request_diffs.merge_request_id
        AND merge_request_diffs.diff_type = #{MergeRequestDiff.diff_types[:regular]}
      )".squish

    self.each_batch do |batch|
      batch.update_all(update)
    end
  end

  DRAFT_REGEX = /\A*#{Gitlab::Regex.merge_request_draft}+\s*/i

  def self.draft?(title)
    !!(title =~ DRAFT_REGEX)
  end

  def self.draftless_title(title)
    title.sub(DRAFT_REGEX, "")
  end

  def self.draft_title(title)
    draft?(title) ? title : "Draft: #{title}"
  end

  class << self
    alias_method :work_in_progress?, :draft?
    alias_method :wipless_title, :draftless_title
    alias_method :wip_title, :draft_title
  end

  def self.participant_includes
    [:assignees, :reviewers] + super
  end

  def self.use_locked_set?
    Feature.enabled?(:unstick_locked_merge_requests_redis)
  end

  def committers(with_merge_commits: false, lazy: false, include_author_when_signed: false)
    strong_memoize_with(:committers, with_merge_commits, lazy, include_author_when_signed) do
      commits.committers(
        with_merge_commits: with_merge_commits,
        lazy: lazy,
        include_author_when_signed: include_author_when_signed
      )
    end
  end

  # Verifies if title has changed not taking into account Draft prefix
  # for merge requests.
  def draftless_title_changed(old_title)
    self.class.draftless_title(old_title) != self.draftless_title
  end
  alias_method :wipless_title_changed, :draftless_title_changed

  def hook_attrs
    Gitlab::HookData::MergeRequestBuilder.new(self).build
  end

  # `from` argument can be a Namespace or Project.
  def to_reference(from = nil, full: false)
    reference = "#{self.class.reference_prefix}#{iid}"

    "#{project.to_reference_base(from, full: full)}#{reference}"
  end

  def context_commits(limit: nil)
    @context_commits ||= merge_request_context_commits.order_by_committed_date_desc.limit(limit).map(&:to_commit)
  end

  def recent_context_commits
    context_commits(limit: MergeRequestDiff::COMMITS_SAFE_SIZE)
  end

  def context_commits_count
    context_commits.count
  end

  def commits(limit: nil, load_from_gitaly: false, page: nil)
    return merge_request_diff.commits(limit: limit, load_from_gitaly: load_from_gitaly, page: page) if merge_request_diff.persisted?

    commits_arr = if compare_commits
                    reversed_commits = compare_commits.reverse
                    limit ? reversed_commits.take(limit) : reversed_commits
                  else
                    []
                  end

    CommitCollection.new(source_project, commits_arr, source_branch)
  end

  def recent_commits(limit: MergeRequestDiff::COMMITS_SAFE_SIZE, load_from_gitaly: false, page: nil)
    commits(limit: limit, load_from_gitaly: load_from_gitaly, page: page)
  end

  def commits_count
    if merge_request_diff.persisted?
      merge_request_diff.commits_count
    elsif compare_commits
      compare_commits.size
    else
      0
    end
  end

  def commit_shas(limit: nil)
    return merge_request_diff.commit_shas(limit: limit) if merge_request_diff.persisted?

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

  def supports_lock_on_merge?
    return false unless merged?

    project.supports_lock_on_merge?
  end

  # Calls `MergeWorker` to proceed with the merge process and
  # updates `merge_jid` with the MergeWorker#jid.
  # This helps tracking enqueued and ongoing merge jobs.
  def merge_async(user_id, params)
    jid = MergeWorker.with_status.perform_async(id, user_id, params.to_h)
    update_column(:merge_jid, jid)

    # merge_ongoing? depends on merge_jid
    # expire etag cache since the attribute is changed without triggering callbacks
    expire_etag_cache
  end

  # Set off a rebase asynchronously, atomically updating the `rebase_jid` of
  # the MR so that the status of the operation can be tracked.
  def rebase_async(user_id, skip_ci: false)
    with_rebase_lock do
      raise ActiveRecord::StaleObjectError if !open? || rebase_in_progress?

      # Although there is a race between setting rebase_jid here and clearing it
      # in the RebaseWorker, it can't do any harm since we check both that the
      # attribute is set *and* that the sidekiq job is still running. So a JID
      # for a completed RebaseWorker is equivalent to a nil JID.
      jid = Sidekiq::Worker.skipping_transaction_check do
        RebaseWorker.with_status.perform_async(id, user_id, skip_ci)
      end

      update_column(:rebase_jid, jid)
    end

    # rebase_in_progress? depends on rebase_jid
    # expire etag cache since the attribute is changed without triggering callbacks
    expire_etag_cache
  end

  def merge_participants
    participants = [author]

    if auto_merge_enabled? && participants.exclude?(merge_user)
      participants << merge_user
    end

    participants.select { |participant| Ability.allowed?(participant, :read_merge_request, self) }
  end

  def first_commit
    compare_commits.present? ? compare_commits.first : merge_request_diff.first_commit
  end

  def raw_diffs(*args)
    compare.present? ? compare.raw_diffs(*args) : merge_request_diff.raw_diffs(*args)
  end

  def diffs_for_streaming(diff_options = {}, &)
    diff = diffable_merge_ref? ? merge_head_diff : merge_request_diff

    offset = diff_options[:offset_index].to_i || 0

    if block_given?
      source_project.repository.diffs_by_changed_paths(diff.diff_refs, offset, &)
    else
      diff.diffs(diff_options)
    end
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

  def note_positions_for_paths(paths, user = nil)
    positions = notes.new_diff_notes.joins(:note_diff_file)
      .where('note_diff_files.old_path IN (?) OR note_diff_files.new_path IN (?)', paths, paths)
      .positions

    collection = Gitlab::Diff::PositionCollection.new(positions, diff_head_sha)

    return collection unless user

    positions = draft_notes
      .authored_by(user)
      .positions
      .select { |pos| paths.include?(pos.file_path) }

    collection.concat(positions)
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

  def diff_stats
    return unless diff_refs

    strong_memoize(:diff_stats) do
      project.repository.diff_stats(diff_refs.base_sha, diff_refs.head_sha)
    end
  end

  def diff_size
    # Calling `merge_request_diff.diffs.real_size` will also perform
    # highlighting, which we don't need here.
    merge_request_diff&.real_size || diff_stats&.real_size || diffs.real_size
  end

  def modified_paths(past_merge_request_diff: nil, fallback_on_overflow: false)
    if past_merge_request_diff
      past_merge_request_diff.modified_paths(fallback_on_overflow: fallback_on_overflow)
    elsif compare
      diff_stats&.paths || compare.modified_paths
    else
      merge_request_diff.modified_paths(fallback_on_overflow: fallback_on_overflow)
    end
  end

  def changed_paths
    project.repository.find_changed_paths(commits, merge_commit_diff_mode: :all_parents)
  end
  request_cache(:changed_paths) { [id, diff_head_sha] }

  def new_paths
    diffs.diff_files.map(&:new_path)
  end

  def diff_base_commit
    if merge_request_diff.persisted?
      merge_request_diff.base_commit
    else
      branch_merge_base_commit
    end
  end

  def diff_start_commit
    if merge_request_diff.persisted?
      merge_request_diff.start_commit
    else
      target_branch_head
    end
  end

  def diff_head_commit
    if merge_request_diff.persisted?
      merge_request_diff.head_commit
    else
      source_branch_head
    end
  end

  def diff_start_sha
    if merge_request_diff.persisted?
      merge_request_diff.start_commit_sha
    else
      target_branch_head.try(:sha)
    end
  end

  def diff_base_sha
    if merge_request_diff.persisted?
      merge_request_diff.base_commit_sha
    else
      branch_merge_base_commit.try(:sha)
    end
  end

  def diff_head_sha
    if merge_request_diff.persisted?
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
      base_sha: branch_merge_base_sha,
      start_sha: target_branch_sha,
      head_sha: source_branch_sha
    )
  end

  def branch_merge_base_sha
    branch_merge_base_commit.try(:sha)
  end

  def existing_mrs_targeting_same_branch
    similar_mrs = target_project
        .merge_requests
        .where(source_branch: source_branch, target_branch: target_branch)
        .where(source_project: source_project)
        .opened

    similar_mrs = similar_mrs.id_not_in(id) if persisted?

    similar_mrs
  end

  def validate_branches
    return unless target_project && source_project

    if target_project == source_project && target_branch == source_branch
      errors.add :branch_conflict, "You can't use same project/branch for source and target"
      return
    end

    [:source_branch, :target_branch].each { |attr| validate_branch_name(attr) }

    if opened?
      conflicting_mr = existing_mrs_targeting_same_branch.first

      if conflicting_mr
        errors.add(
          :validate_branches,
          conflicting_mr_message(conflicting_mr)
        )
      end
    end
  end

  def conflicting_mr_message(conflicting_mr)
    format(
      _("Another open merge request already exists for this source branch: %{conflicting_mr_reference}"),
      conflicting_mr_reference: conflicting_mr.to_reference
    )
  end

  def validate_branch_name(attr)
    return unless will_save_change_to_attribute?(attr)

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

    errors.add :validate_fork, 'Source project is not a fork of the target project'
  end

  def validate_reviewer_size_length
    return true unless reviewers.size > MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS

    errors.add :reviewers,
      ->(_object, _data) { self.class.max_number_of_assignees_or_reviewers_message }
  end

  def merge_ongoing?
    # While the MergeRequest is locked, it should present itself as 'merge ongoing'.
    # The unlocking process is handled by StuckMergeJobsWorker scheduled in Cron.
    return true if locked?

    !!merge_jid && !merged? && Gitlab::SidekiqStatus.running?(merge_jid)
  end

  def closed_or_merged_without_fork?
    (closed? || merged?) && source_project_missing?
  end

  def source_project_missing?
    return false unless for_fork?
    return true unless source_project

    !source_project.in_fork_network_of?(target_project)
  end

  def reopenable?
    closed? && !source_project_missing? && source_branch_exists?
  end

  def can_be_closed?
    opened?
  end

  def ensure_merge_request_diff
    merge_request_diff.persisted? || create_merge_request_diff
  end

  def create_merge_request_diff
    fetch_ref!

    # n+1: https://gitlab.com/gitlab-org/gitlab/-/issues/19377
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

  def previous_diff
    merge_request_diffs.order(id: :desc).offset(1).take
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

  def check_mergeability(async: false, sync_retry_lease: false)
    return unless recheck_merge_status?

    check_service = MergeRequests::MergeabilityCheckService.new(self)

    if async
      check_service.async_execute
    else
      check_service.execute(retry_lease: sync_retry_lease)
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

  def diffable_merge_ref?
    open? && merge_head_diff.present? && can_be_merged?
  end

  # Returns boolean indicating the merge_status should be rechecked in order to
  # switch to either can_be_merged or cannot_be_merged.
  def recheck_merge_status?
    self.class.state_machines[:merge_status].check_state?(merge_status)
  end

  def merge_event
    @merge_event ||= target_project.events.where(target_id: self.id, target_type: "MergeRequest", action: :merged).last
  end

  def closed_event
    @closed_event ||= target_project.events.where(target_id: self.id, target_type: "MergeRequest", action: :closed).last
  end

  def draft?
    self.class.draft?(title)
  end
  alias_method :work_in_progress?, :draft?

  def draftless_title
    self.class.draftless_title(self.title)
  end
  alias_method :wipless_title, :draftless_title

  def draft_title
    self.class.draft_title(self.title)
  end
  alias_method :wip_title, :draft_title

  def skipped_mergeable_checks(options = {})
    merge_when_checks_pass_strat = options[:auto_merge_strategy] == ::AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS || options[:auto_merge_strategy] == ::AutoMergeService::STRATEGY_ADD_TO_MERGE_TRAIN_WHEN_CHECKS_PASS

    {
      skip_ci_check: options.fetch(:auto_merge_requested, false),
      skip_approved_check: merge_when_checks_pass_strat,
      skip_draft_check: merge_when_checks_pass_strat,
      skip_blocked_check: merge_when_checks_pass_strat,
      skip_discussions_check: merge_when_checks_pass_strat,
      skip_external_status_check: merge_when_checks_pass_strat,
      skip_requested_changes_check: merge_when_checks_pass_strat,
      skip_locked_paths_check: merge_when_checks_pass_strat,
      skip_jira_check: merge_when_checks_pass_strat,
      skip_locked_lfs_files_check: merge_when_checks_pass_strat,
      skip_security_policy_check: merge_when_checks_pass_strat,
      skip_merge_time_check: merge_when_checks_pass_strat
    }
  end

  # mergeable_state_check_params allows a hash of merge checks to skip or not
  # skip_ci_check
  # skip_discussions_check
  # skip_draft_check
  # skip_approved_check
  # skip_blocked_check
  # skip_external_status_check
  # skip_requested_changes_check
  # skip_locked_paths_check
  # skip_jira_check
  # skip_locked_lfs_files_check
  def mergeable?(check_mergeability_retry_lease: false, skip_rebase_check: false, **mergeable_state_check_params)
    return false unless mergeable_state?(**mergeable_state_check_params)

    check_mergeability(sync_retry_lease: check_mergeability_retry_lease)
    mergeable_git_state?(skip_rebase_check: skip_rebase_check)
  end

  def self.mergeable_state_checks
    # We want to have the cheapest checks first in the list, that way we can
    #   fail fast before running the more expensive ones.
    #
    [
      ::MergeRequests::Mergeability::CheckOpenStatusService,
      ::MergeRequests::Mergeability::CheckMergeTimeService,
      ::MergeRequests::Mergeability::CheckDraftStatusService,
      ::MergeRequests::Mergeability::CheckCommitsStatusService,
      ::MergeRequests::Mergeability::CheckDiscussionsStatusService,
      ::MergeRequests::Mergeability::CheckCiStatusService,
      ::MergeRequests::Mergeability::CheckLfsFileLocksService
    ]
  end

  def self.mergeable_git_state_checks
    [
      ::MergeRequests::Mergeability::CheckConflictStatusService,
      ::MergeRequests::Mergeability::CheckRebaseStatusService
    ]
  end

  def self.all_mergeability_checks
    mergeable_state_checks + mergeable_git_state_checks
  end

  # mergeable_state_check_params allows a hash of merge checks to skip or not
  # skip_ci_check
  # skip_discussions_check
  # skip_draft_check
  # skip_approved_check
  # skip_blocked_check
  # skip_external_status_check
  # skip_requested_changes_check
  # skip_jira_check
  def mergeable_state?(**params)
    execute_merge_checks(
      self.class.mergeable_state_checks,
      params: params,
      execute_all: false
    ).success?
  end

  # This runs only git related checks
  def mergeable_git_state?(**params)
    execute_merge_checks(
      self.class.mergeable_git_state_checks,
      params: params,
      execute_all: false
    ).success?
  end

  # This runs all the checks
  def mergeability_checks_pass?(**params)
    execute_merge_checks(
      self.class.all_mergeability_checks,
      params: params,
      execute_all: false
    ).success?
  end

  def all_mergeability_checks_results
    execute_merge_checks(
      self.class.all_mergeability_checks,
      execute_all: true
    ).payload[:results]
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
    source_project &&
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

    merge_params['auto_merge_strategy'] || default_auto_merge_strategy
  end

  def default_auto_merge_strategy
    AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS
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
    return true unless only_allow_merge_if_all_discussions_are_resolved?

    unresolved_notes.none?(&:to_be_resolved?)
  end

  def for_fork?
    target_project != source_project
  end

  def for_same_project?
    target_project == source_project
  end

  # If the merge request closes any issues, save this information in the
  # `MergeRequestsClosingIssues` model. This is a performance optimization.
  # Calculating this information for a number of merge requests requires
  # running `ReferenceExtractor` on each of them separately.
  # This optimization does not apply to issues from external sources.
  def cache_merge_request_closes_issues!(current_user = self.author)
    return if closed? || merged?

    issues_to_close_ids = closes_issues(current_user).reject { |issue| issue.is_a?(ExternalIssue) }.map(&:id)

    transaction do
      merge_requests_closing_issues.from_mr_description.delete_all

      # These might have been created manually from the work item interface
      issue_ids_to_update = merge_requests_closing_issues
        .where(from_mr_description: false, issue_id: issues_to_close_ids)
        .pluck(:issue_id)

      if issue_ids_to_update.any?
        merge_requests_closing_issues.where(issue_id: issue_ids_to_update).update_all(from_mr_description: true)
      end

      issue_ids_to_create = issues_to_close_ids - issue_ids_to_update
      next unless issue_ids_to_create.any?

      now = Time.zone.now
      new_associations = issue_ids_to_create.map do |issue_id|
        MergeRequestsClosingIssues.new(
          issue_id: issue_id,
          merge_request_id: id,
          from_mr_description: true,
          created_at: now,
          updated_at: now
        )
      end

      # We can't skip validations here in bulk insert as we don't have a unique constraint on the DB.
      # We can skip validations once we have validated the unique constraint
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/456965
      MergeRequestsClosingIssues.bulk_insert!(new_associations, batch_size: 100)
    end
  end

  def visible_closing_issues_for(current_user = self.author)
    strong_memoize(:visible_closing_issues_for) do
      visible_issues = if self.target_project.has_external_issue_tracker?
                         closes_issues(current_user)
                       else
                         cached_closes_issues.select do |issue|
                           Ability.allowed?(current_user, :read_issue, issue)
                         end
                       end

      ActiveRecord::Associations::Preloader.new(
        records: visible_issues.select { |issue| issue.is_a?(Issue) },
        associations: :project
      ).call
      # Exclude isues that have been cached but their project setting has been disabled, or they belong to a group
      visible_issues.select do |issue|
        !issue.is_a?(Issue) || issue.autoclose_by_merged_closing_merge_request?
      end
    end
  end

  # Return the set of issues that will be closed if this merge request is accepted.
  def closes_issues(current_user = self.author)
    if target_branch == project.default_branch
      messages = [title, description]
      messages.concat(commits.map(&:safe_message)) if merge_request_diff.persisted?

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

  def related_issues(user)
    visible_notes = user.can?(:read_internal_note, project) ? notes : notes.not_internal

    messages = [title, description, *visible_notes.pluck(:note)]
    messages += commits.map(&:safe_message) if merge_request_diff.persisted?

    ext = Gitlab::ReferenceExtractor.new(project, user)
    ext.analyze(messages.join("\n"))

    ext.issues
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

  def default_merge_commit_message(include_description: false, user: nil)
    if self.target_project.merge_commit_template.present? && !include_description
      return ::Gitlab::MergeRequests::MessageGenerator.new(merge_request: self, current_user: user).merge_commit_message
    end

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

    message << description if include_description && description.present?
    message << "See merge request #{to_reference(full: true)}"

    message.join("\n\n")
  end

  def default_squash_commit_message(user: nil)
    squash_commit_message = ::Gitlab::MergeRequests::MessageGenerator.new(merge_request: self, current_user: user).squash_commit_message.presence

    squash_commit_message || title
  end

  # Returns the oldest multi-line commit
  def first_multiline_commit
    strong_memoize(:first_multiline_commit) do
      recent_commits.without_merge_commits.reverse_each.find(&:description?)
    end
  end

  def squash_on_merge?
    return true if squash_always?
    return false if squash_never?

    squash?
  end

  def has_ci?
    return false if has_no_commits?

    !!(head_pipeline_id || all_pipelines.any? || source_project&.ci_integration)
  end

  def branch_missing?
    !source_branch_exists? || !target_branch_exists?
  end

  def broken?
    has_no_commits? || branch_missing? || cannot_be_merged?
  end

  def can_be_merged_by?(user, skip_collaboration_check: false)
    access = ::Gitlab::UserAccess.new(user, container: project, skip_collaboration_check: skip_collaboration_check)
    access.can_update_branch?(target_branch)
  end

  def can_be_merged_via_command_line_by?(user)
    access = ::Gitlab::UserAccess.new(user, container: project)
    access.can_push_to_branch?(target_branch)
  end

  def only_allow_merge_if_pipeline_succeeds?
    project.only_allow_merge_if_pipeline_succeeds?(inherit_group_setting: true)
  end

  def allow_merge_without_pipeline?
    project.allow_merge_without_pipeline?(inherit_group_setting: true)
  end

  def only_allow_merge_if_all_discussions_are_resolved?
    project.only_allow_merge_if_all_discussions_are_resolved?(inherit_group_setting: true)
  end

  # We use a heuristic of if there are pipeline created, being created, or a ci integration is setup
  def has_ci_enabled?
    has_ci? || (Feature.enabled?(:change_ci_enabled_hurestic, self.project) ? pipeline_creating? : project.has_ci?)
  end

  def pipeline_creating?
    Ci::PipelineCreation::Requests.pipeline_creating_for_merge_request?(self)
  end

  def environments_in_head_pipeline(deployment_status: nil)
    diff_head_pipeline&.environments_in_self_and_project_descendants(deployment_status: deployment_status) || Environment.none
  end

  def fetch_ref!
    target_project.repository.fetch_source_branch!(source_project.repository, source_branch, ref_path)
    expire_ancestor_cache
  end

  # Returns the current merge-ref HEAD commit.
  #
  def merge_ref_head
    return project.repository.commit(merge_ref_sha) if merge_ref_sha

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

  def schedule_cleanup_refs(only: :all)
    if Feature.enabled?(:merge_request_delete_gitaly_refs_in_batches, target_project)
      async_cleanup_refs(only: only)
    elsif Feature.enabled?(:merge_request_cleanup_ref_worker_async, target_project)
      MergeRequests::CleanupRefWorker.perform_async(id, only.to_s)
    else
      cleanup_refs(only: only)
    end
  end

  def refs_to_cleanup(only: :all)
    target_refs = []
    target_refs << ref_path       if %i[all head].include?(only)
    target_refs << merge_ref_path if %i[all merge].include?(only)
    target_refs << train_ref_path if %i[all train].include?(only)
    target_refs
  end

  def cleanup_refs(only: :all)
    project.repository.delete_refs(*refs_to_cleanup(only: only))
  end

  def async_cleanup_refs(only: :all)
    project.repository.async_delete_refs(*refs_to_cleanup(only: only))
  end

  def self.merge_request_ref?(ref)
    ref.start_with?("refs/#{Repository::REF_MERGE_REQUEST}/")
  end

  def self.merge_train_ref?(ref)
    %r{\Arefs/#{Repository::REF_MERGE_REQUEST}/\d+/train\z}o.match?(ref)
  end

  def in_locked_state
    # This method raises an error when adding to Redis set fails. This is so
    # we can retry merging if it wasn't added to ensure that the MR gets added
    # to locked set for unsticking in case it gets into a stuck state during
    # the merge process.
    add_to_locked_set
    lock_mr
    yield
  ensure
    unlock_mr if locked?

    # We only remove it from the locked set if it's no longer locked as it means
    # the MR is either unlocked or merged.
    remove_from_locked_set unless locked?
  end

  def update_and_mark_in_progress_merge_commit_sha(commit_id)
    self.update(in_progress_merge_commit_sha: commit_id)
    # Since another process checks for matching merge request, we need
    # to make it possible to detect whether the query should go to the
    # primary.
    target_project.sticking.stick(:project, target_project.id)
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
      Ci::PipelinesForMergeRequestFinder.new(self, nil).all
    end
  end

  def update_head_pipeline
    find_diff_head_pipeline.try do |pipeline|
      self.head_pipeline = pipeline

      next unless head_pipeline_id_changed?

      update_columns(
        head_pipeline_id: head_pipeline.id,
        retargeted: false
      )
    end
  end

  def has_test_reports?
    diff_head_pipeline&.complete_and_has_reports?(Ci::JobArtifact.of_report_type(:test))
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
      variables.append(key: 'CI_MERGE_REQUEST_TARGET_BRANCH_PROTECTED', value: ProtectedBranch.protected?(target_project, target_branch).to_s)
      variables.append(key: 'CI_MERGE_REQUEST_TITLE', value: title)

      mr_description, mr_description_truncated = truncate_mr_description
      variables.append(key: 'CI_MERGE_REQUEST_DESCRIPTION', value: mr_description)
      variables.append(key: 'CI_MERGE_REQUEST_DESCRIPTION_IS_TRUNCATED', value: mr_description_truncated)
      variables.append(key: 'CI_MERGE_REQUEST_ASSIGNEES', value: assignee_username_list) if assignees.present?
      variables.append(key: 'CI_MERGE_REQUEST_MILESTONE', value: milestone.title) if milestone
      variables.append(key: 'CI_MERGE_REQUEST_LABELS', value: label_names.join(',')) if labels.present?
      variables.append(key: 'CI_MERGE_REQUEST_SQUASH_ON_MERGE', value: squash_on_merge?.to_s)
      variables.concat(source_project_variables)
    end
  end

  def compare_test_reports
    unless has_test_reports?
      return { status: :error, status_reason: 'This merge request does not have test reports' }
    end

    compare_reports(Ci::CompareTestReportsService)
  end

  def has_accessibility_reports?
    diff_head_pipeline.present? && diff_head_pipeline.complete_and_has_reports?(Ci::JobArtifact.of_report_type(:accessibility))
  end

  def has_coverage_reports?
    diff_head_pipeline&.has_coverage_reports?
  end

  def has_terraform_reports?
    diff_head_pipeline&.has_reports?(Ci::JobArtifact.of_report_type(:terraform))
  end

  def compare_accessibility_reports
    unless has_accessibility_reports?
      return { status: :error, status_reason: _('This merge request does not have accessibility reports') }
    end

    compare_reports(Ci::CompareAccessibilityReportsService)
  end

  # TODO: this method and compare_test_reports use the same
  # result type, which is handled by the controller's #reports_response.
  # we should minimize mistakes by isolating the common parts.
  # issue: https://gitlab.com/gitlab-org/gitlab/issues/34224
  def find_coverage_reports
    unless has_coverage_reports?
      return { status: :error, status_reason: 'This merge request does not have coverage reports' }
    end

    compare_reports(Ci::GenerateCoverageReportsService)
  end

  def has_codequality_mr_diff_report?
    diff_head_pipeline&.has_codequality_mr_diff_report?
  end

  # TODO: this method and compare_test_reports use the same
  # result type, which is handled by the controller's #reports_response.
  # we should minimize mistakes by isolating the common parts.
  # issue: https://gitlab.com/gitlab-org/gitlab/issues/34224
  def find_codequality_mr_diff_reports
    unless has_codequality_mr_diff_report?
      return { status: :error, status_reason: 'This merge request does not have codequality mr diff reports' }
    end

    compare_reports(Ci::GenerateCodequalityMrDiffReportService)
  end

  def has_codequality_reports?
    diff_head_pipeline&.complete_and_has_reports?(Ci::JobArtifact.of_report_type(:codequality))
  end

  def compare_codequality_reports
    unless has_codequality_reports?
      return { status: :error, status_reason: _('This merge request does not have codequality reports') }
    end

    compare_reports(Ci::CompareCodequalityReportsService)
  end

  def find_terraform_reports
    unless has_terraform_reports?
      return { status: :error, status_reason: 'This merge request does not have terraform reports' }
    end

    compare_reports(Ci::GenerateTerraformReportsService)
  end

  def has_exposed_artifacts?
    diff_head_pipeline&.has_exposed_artifacts?
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
  def compare_reports(service_class, current_user = nil, report_type = nil, additional_params = {})
    with_reactive_cache(service_class.name, current_user&.id, report_type) do |data|
      unless service_class.new(project, current_user, id: id, report_type: report_type, additional_params: additional_params)
        .latest?(comparison_base_pipeline(service_class), diff_head_pipeline, data)
        raise InvalidateReactiveCache
      end

      data
    end || { status: :parsing }
  end

  def has_sast_reports?
    !!diff_head_pipeline&.complete_or_manual_and_has_reports?(::Ci::JobArtifact.of_report_type(:sast))
  end

  def has_secret_detection_reports?
    !!diff_head_pipeline&.complete_or_manual_and_has_reports?(::Ci::JobArtifact.of_report_type(:secret_detection))
  end

  def compare_sast_reports(current_user)
    return missing_report_error("SAST") unless has_sast_reports?

    compare_reports(::Ci::CompareSecurityReportsService, current_user, 'sast')
  end

  def compare_secret_detection_reports(current_user)
    return missing_report_error("secret detection") unless has_secret_detection_reports?

    compare_reports(::Ci::CompareSecurityReportsService, current_user, 'secret_detection')
  end

  def calculate_reactive_cache(identifier, current_user_id = nil, report_type = nil, *args)
    service_class = identifier.constantize

    # TODO: the type check should change to something that includes exposed artifacts service
    # issue: https://gitlab.com/gitlab-org/gitlab/issues/34224
    raise NameError, service_class unless service_class < Ci::CompareReportsBaseService

    current_user = User.find_by(id: current_user_id)
    service_class.new(project, current_user, id: id, report_type: report_type).execute(comparison_base_pipeline(service_class), diff_head_pipeline)
  end

  MAX_RECENT_DIFF_HEAD_SHAS = 100

  def recent_diff_head_shas(limit = MAX_RECENT_DIFF_HEAD_SHAS)
    # see MergeRequestDiff.recent
    return merge_request_diffs.to_a.sort_by(&:id).reverse.first(limit).pluck(:head_commit_sha) if merge_request_diffs.loaded?

    merge_request_diffs.recent(limit).pluck(:head_commit_sha)
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

  def squash_commit
    @squash_commit ||= project.commit(squash_commit_sha) if squash_commit_sha
  end

  def short_merge_commit_sha
    Commit.truncate_sha(merge_commit_sha) if merge_commit_sha
  end

  def merged_commit_sha
    return unless merged?

    sha = super || merge_commit_sha || squash_commit_sha || diff_head_sha
    sha.presence
  end

  def short_merged_commit_sha
    if sha = merged_commit_sha
      Commit.truncate_sha(sha)
    end
  end

  # Exists only for merged merge requests
  def commit_to_revert
    return unless merged?

    # By default, it's equal to a merge commit
    return merge_commit if merge_commit

    # But in case of fast-forward merge merge commits are not created
    # To solve that we can use `squash_commit` if the merge request was squashed
    return squash_commit if squash_commit

    # Edge case: one commit in the merge request without merge or squash commit
    return project.commit(diff_head_sha) if commits_count == 1

    nil
  end

  def commit_to_cherry_pick
    commit_to_revert
  end

  def can_be_reverted?(current_user)
    return false unless merged_at

    commit = commit_to_revert
    return false unless commit

    # It is not guaranteed that Note#created_at will be strictly later than
    # MergeRequestMetric#merged_at. Nanoseconds on MySQL may break this
    # comparison, as will a HA environment if clocks are not *precisely*
    # synchronized. Add a minute's leeway to compensate for both possibilities
    cutoff = merged_at - 1.minute

    notes_association = notes_with_associations.where('created_at >= ?', cutoff)

    !commit.has_been_reverted?(current_user, notes_association)
  end

  def merged_at
    strong_memoize(:merged_at) do
      next unless merged?

      metrics&.merged_at ||
        merge_event&.created_at ||
        resource_state_events.find_by(state: :merged)&.created_at ||
        notes.system.reorder(nil).find_by(note: 'merged')&.created_at
    end
  end

  def can_be_cherry_picked?
    commit_to_cherry_pick.present?
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

    active_discussions_resolved = active_diff_discussions.all?(&:resolved?)

    service = Discussions::UpdateDiffPositionService.new(
      self.project,
      current_user,
      old_diff_refs: old_diff_refs,
      new_diff_refs: new_diff_refs,
      paths: paths
    )

    active_diff_discussions.each do |discussion|
      service.execute(discussion)
      discussion.clear_memoized_values
    end

    # If they were all already resolved, this method will have already been called.
    # If they all don't get resolved, we don't need to call the method
    # If they go from unresolved -> resolved, then we call the method
    if !active_discussions_resolved &&
        active_diff_discussions.all?(&:resolved?) &&
        project.resolve_outdated_diff_discussions?
      MergeRequests::ResolvedDiscussionNotificationService
        .new(project: project, current_user: current_user)
        .execute(self)
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

  def keep_around_commit
    project.repository.keep_around(self.merge_commit_sha, source: self.class.name)
  end

  def has_commits?
    merge_request_diff.persisted? && commits_count.to_i > 0
  end

  def has_no_commits?
    !has_commits?
  end

  def pipeline_coverage_delta
    if base_pipeline&.coverage && head_pipeline&.coverage
      head_pipeline.coverage - base_pipeline.coverage
    end
  end

  # Overridden in EE
  def use_merge_base_pipeline_for_comparison?(_)
    false
  end

  def comparison_base_pipeline(service_class)
    (use_merge_base_pipeline_for_comparison?(service_class) && merge_base_pipeline) || base_pipeline
  end

  def base_pipeline
    @base_pipeline ||= base_pipelines.last
  end

  def merge_base_pipeline
    @merge_base_pipeline ||= merge_base_pipelines.last
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
    return metrics&.first_contribution if merged? & metrics.present?

    !project.merge_requests.merged.exists?(author_id: author_id)
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

  def find_diff_head_pipeline
    all_pipelines.for_sha_or_source_sha(diff_head_sha).first
  end

  def real_time_notes_enabled?
    true
  end

  def recent_visible_deployments
    deployments.visible.includes(:environment).order(id: :desc).limit(10)
  end

  def banzai_render_context(field)
    super.merge(label_url_method: :project_merge_requests_url)
  end

  def ensure_metrics!
    MergeRequest::Metrics.record!(self)
  end

  def allows_reviewers?
    true
  end

  def allows_multiple_assignees?
    project.allows_multiple_merge_request_assignees?
  end

  def allows_multiple_reviewers?
    project.allows_multiple_merge_request_reviewers?
  end

  def supports_assignee?
    true
  end

  def find_assignee(user)
    merge_request_assignees.find_by(user_id: user.id)
  end

  def merge_request_assignees_with(user_ids)
    merge_request_assignees.where(user_id: user_ids)
  end

  def find_reviewer(user)
    merge_request_reviewers.find_by(user_id: user.id)
  end

  def merge_request_reviewers_with(user_ids)
    merge_request_reviewers.where(user_id: user_ids)
  end

  def create_requested_changes(user)
    # Overridden in EE
  end

  def destroy_requested_changes(user)
    # Overridden in EE
  end

  def batch_update_reviewer_state(user_ids, state)
    merge_request_reviewers.where(user_id: user_ids).update_all(state: state)
  end

  def enabled_reports
    {
      sast: report_type_enabled?(:sast),
      secret_detection: report_type_enabled?(:secret_detection)
    }
  end

  def includes_ci_config?
    return false unless diff_stats

    diff_stats.map(&:path).include?(project.ci_config_path_or_default)
  end

  def context_commits_diff
    strong_memoize(:context_commits_diff) do
      ContextCommitsDiff.new(self)
    end
  end

  def target_default_branch?
    target_branch == project.default_branch
  end

  def merge_blocked_by_other_mrs?
    false # Overridden in EE
  end

  def execute_merge_checks(checks, params: {}, execute_all: false)
    # rubocop: disable CodeReuse/ServiceClass
    MergeRequests::Mergeability::RunChecksService
      .new(merge_request: self, params: params)
      .execute(checks, execute_all: execute_all)
    # rubocop: enable CodeReuse/ServiceClass
  end

  def can_suggest_reviewers?
    false # overridden in EE
  end

  def hidden?
    Feature.enabled?(:hide_merge_requests_from_banned_users) && author&.banned?
  end

  def diffs_batch_cache_with_max_age?
    Feature.enabled?(:diffs_batch_cache_with_max_age, project)
  end

  def prepared?
    prepared_at.present?
  end

  def prepare
    NewMergeRequestWorker.perform_async(id, author_id)
  end

  def check_for_spam?(*)
    spammable_attribute_changed? && project.public?
  end

  def missing_required_squash?
    !squash && squash_always?
  end

  def current_patch_id_sha
    merge_request_diff.get_patch_id_sha
  end

  def diff_head_pipeline_considered_in_progress?
    pipeline = diff_head_pipeline
    return false unless pipeline

    # We allow auto-merge on blocked pipelines when "Pipelines must succeed" is
    # enabled, because in that case the pipeline blocks the merge. When
    # "Pipelines must succeed" is disabled, immediate merges are neither blocked
    # nor discouraged on blocked pipelines, so auto merge should not wait for
    # the pipeline to finish.
    if only_allow_merge_if_pipeline_succeeds?
      !pipeline.complete?
    else
      pipeline.active? || pipeline.created?
    end
  end

  def temporarily_unapproved?
    false
  end

  def has_jira_issue_keys?
    return false unless project&.jira_integration&.reference_pattern

    Atlassian::JiraIssueKeyExtractor.has_keys?(
      title,
      description,
      custom_regex: project.jira_integration.reference_pattern
    )
  end

  def merge_exclusive_lease
    lease_key = ['merge_requests_merge_service', id].join(':')

    Gitlab::ExclusiveLease.new(lease_key, timeout: MERGE_LEASE_TIMEOUT)
  end

  def source_and_target_branches_exist?
    source_branch_sha.present? && target_branch_sha.present?
  end

  def has_diffs?
    Gitlab::Git::Compare.new(
      project.repository.raw_repository,
      target_branch_sha,
      source_branch_sha
    ).diffs.any?
  end

  def add_to_locked_set
    return unless self.class.use_locked_set?

    Gitlab::MergeRequests::LockedSet.add(self.id, rescue_connection_error: false)
  end

  def remove_from_locked_set
    return unless self.class.use_locked_set?

    Gitlab::MergeRequests::LockedSet.remove(self.id)
  end

  def first_diffs_slice(limit)
    diff = diffable_merge_ref? ? merge_head_diff : merge_request_diff

    diff.paginated_diffs(1, limit).diff_files
  end

  def squash_option
    target_project.project_setting
  end

  delegate :squash_always?, :squash_never?, :squash_enabled_by_default?, :squash_readonly?, to: :squash_option

  private

  def merge_base_pipelines
    return ::Ci::Pipeline.none unless diff_head_pipeline&.target_sha

    target_branch_pipelines_for(sha: diff_head_pipeline.target_sha)
  end

  def base_pipelines
    target_branch_pipelines_for(sha: diff_base_sha)
  end

  def target_branch_pipelines_for(sha:)
    project.ci_pipelines
           .where(sha: sha, ref: target_branch)
  end

  def set_draft_status
    self.draft = draft?
  end

  def expire_ancestor_cache
    project.repository.expire_ancestor_cache(target_branch_sha, diff_head_sha)
  end

  def missing_report_error(report_type)
    { status: :error, status_reason: "This merge request does not have #{report_type} reports" }
  end

  def with_rebase_lock
    with_retried_nowait_lock { yield }
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
    raise RebaseLockTimeout, _('Failed to enqueue the rebase operation, possibly due to a long-lived transaction. Try again later.')
  end

  def source_project_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      break variables unless source_project

      variables.append(key: 'CI_MERGE_REQUEST_SOURCE_PROJECT_ID', value: source_project.id.to_s)
      variables.append(key: 'CI_MERGE_REQUEST_SOURCE_PROJECT_PATH', value: source_project.full_path)
      variables.append(key: 'CI_MERGE_REQUEST_SOURCE_PROJECT_URL', value: source_project.web_url)
      variables.append(key: 'CI_MERGE_REQUEST_SOURCE_BRANCH_NAME', value: source_branch.to_s)
      variables.append(key: 'CI_MERGE_REQUEST_SOURCE_BRANCH_PROTECTED', value: ProtectedBranch.protected?(source_project, source_branch).to_s)
    end
  end

  def expire_etag_cache
    return unless project.namespace

    key = Gitlab::Routing.url_helpers.cached_widget_project_json_merge_request_path(project, self, format: :json)
    Gitlab::EtagCaching::Store.new.touch(key)
  end

  def report_type_enabled?(report_type)
    if report_type == :license_scanning
      ::Gitlab::LicenseScanning.scanner_for_pipeline(project, diff_head_pipeline).has_data?
    else
      !!diff_head_pipeline&.batch_lookup_report_artifact_for_file_type(report_type)
    end
  end

  def truncate_mr_description
    if description && description.length > CI_MERGE_REQUEST_DESCRIPTION_MAX_LENGTH
      [description.truncate(CI_MERGE_REQUEST_DESCRIPTION_MAX_LENGTH), 'true']
    else
      [description, 'false']
    end
  end
end

MergeRequest.prepend_mod_with('MergeRequest')
