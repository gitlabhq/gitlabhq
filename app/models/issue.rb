# frozen_string_literal: true

require 'carrierwave/orm/activerecord'

class Issue < ApplicationRecord
  include AtomicInternalId
  include IidRoutes
  include Issuable
  include Noteable
  include Referable
  include Spammable
  include FasterCacheKeys
  include RelativePositioning
  include TimeTrackable
  include ThrottledTouch
  include LabelEventable
  include IgnorableColumns
  include MilestoneEventable
  include WhereComposite
  include StateEventable
  include IdInOrdered
  include Presentable
  include IssueAvailableFeatures
  include Todoable
  include FromUnion
  include EachBatch

  extend ::Gitlab::Utils::Override

  DueDateStruct                   = Struct.new(:title, :name).freeze
  NoDueDate                       = DueDateStruct.new('No Due Date', '0').freeze
  AnyDueDate                      = DueDateStruct.new('Any Due Date', '').freeze
  Overdue                         = DueDateStruct.new('Overdue', 'overdue').freeze
  DueThisWeek                     = DueDateStruct.new('Due This Week', 'week').freeze
  DueThisMonth                    = DueDateStruct.new('Due This Month', 'month').freeze
  DueNextMonthAndPreviousTwoWeeks = DueDateStruct.new('Due Next Month And Previous Two Weeks', 'next_month_and_previous_two_weeks').freeze

  SORTING_PREFERENCE_FIELD = :issues_sort

  # Types of issues that should be displayed on lists across the app
  # for example, project issues list, group issues list and issue boards.
  # Some issue types, like test cases, should be hidden by default.
  TYPES_FOR_LIST = %w(issue incident).freeze

  belongs_to :project
  has_one :namespace, through: :project

  belongs_to :duplicated_to, class_name: 'Issue'
  belongs_to :closed_by, class_name: 'User'
  belongs_to :iteration, foreign_key: 'sprint_id'

  belongs_to :moved_to, class_name: 'Issue'
  has_one :moved_from, class_name: 'Issue', foreign_key: :moved_to_id

  has_internal_id :iid, scope: :project, track_if: -> { !importing? }

  has_many :events, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  has_many :merge_requests_closing_issues,
    class_name: 'MergeRequestsClosingIssues',
    dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  has_many :issue_assignees
  has_many :issue_email_participants
  has_many :assignees, class_name: "User", through: :issue_assignees
  has_many :zoom_meetings
  has_many :user_mentions, class_name: "IssueUserMention", dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
  has_many :sent_notifications, as: :noteable
  has_many :designs, class_name: 'DesignManagement::Design', inverse_of: :issue
  has_many :design_versions, class_name: 'DesignManagement::Version', inverse_of: :issue do
    def most_recent
      ordered.first
    end
  end

  has_one :issuable_severity
  has_one :sentry_issue
  has_one :alert_management_alert, class_name: 'AlertManagement::Alert'
  has_and_belongs_to_many :self_managed_prometheus_alert_events, join_table: :issues_self_managed_prometheus_alert_events # rubocop: disable Rails/HasAndBelongsToMany
  has_and_belongs_to_many :prometheus_alert_events, join_table: :issues_prometheus_alert_events # rubocop: disable Rails/HasAndBelongsToMany
  has_many :prometheus_alerts, through: :prometheus_alert_events

  accepts_nested_attributes_for :issuable_severity, update_only: true
  accepts_nested_attributes_for :sentry_issue

  validates :project, presence: true
  validates :issue_type, presence: true

  enum issue_type: {
    issue: 0,
    incident: 1,
    test_case: 2, ## EE-only
    requirement: 3 ## EE-only
  }

  alias_method :issuing_parent, :project

  alias_attribute :external_author, :service_desk_reply_to

  scope :in_projects, ->(project_ids) { where(project_id: project_ids) }
  scope :not_in_projects, ->(project_ids) { where.not(project_id: project_ids) }

  scope :with_due_date, -> { where.not(due_date: nil) }
  scope :without_due_date, -> { where(due_date: nil) }
  scope :due_before, ->(date) { where('issues.due_date < ?', date) }
  scope :due_between, ->(from_date, to_date) { where('issues.due_date >= ?', from_date).where('issues.due_date <= ?', to_date) }
  scope :due_tomorrow, -> { where(due_date: Date.tomorrow) }
  scope :not_authored_by, ->(user) { where.not(author_id: user) }

  scope :order_due_date_asc, -> { reorder(::Gitlab::Database.nulls_last_order('due_date', 'ASC')) }
  scope :order_due_date_desc, -> { reorder(::Gitlab::Database.nulls_last_order('due_date', 'DESC')) }
  scope :order_closest_future_date, -> { reorder(Arel.sql('CASE WHEN issues.due_date >= CURRENT_DATE THEN 0 ELSE 1 END ASC, ABS(CURRENT_DATE - issues.due_date) ASC')) }
  scope :order_relative_position_asc, -> { reorder(::Gitlab::Database.nulls_last_order('relative_position', 'ASC')) }
  scope :order_relative_position_desc, -> { reorder(::Gitlab::Database.nulls_first_order('relative_position', 'DESC')) }
  scope :order_closed_date_desc, -> { reorder(closed_at: :desc) }
  scope :order_created_at_desc, -> { reorder(created_at: :desc) }
  scope :order_severity_asc, -> { includes(:issuable_severity).order('issuable_severities.severity ASC NULLS FIRST') }
  scope :order_severity_desc, -> { includes(:issuable_severity).order('issuable_severities.severity DESC NULLS LAST') }

  scope :preload_associated_models, -> { preload(:assignees, :labels, project: :namespace) }
  scope :with_web_entity_associations, -> { preload(:author, project: [:project_feature, :route, namespace: :route]) }
  scope :preload_awardable, -> { preload(:award_emoji) }
  scope :with_label_attributes, ->(label_attributes) { joins(:labels).where(labels: label_attributes) }
  scope :with_alert_management_alerts, -> { joins(:alert_management_alert) }
  scope :with_prometheus_alert_events, -> { joins(:issues_prometheus_alert_events) }
  scope :with_self_managed_prometheus_alert_events, -> { joins(:issues_self_managed_prometheus_alert_events) }
  scope :with_api_entity_associations, -> {
    preload(:timelogs, :closed_by, :assignees, :author, :labels,
      milestone: { project: [:route, { namespace: :route }] },
      project: [:route, { namespace: :route }])
  }
  scope :with_issue_type, ->(types) { where(issue_type: types) }

  scope :public_only, -> { where(confidential: false) }
  scope :confidential_only, -> { where(confidential: true) }

  scope :counts_by_state, -> { reorder(nil).group(:state_id).count }

  scope :service_desk, -> { where(author: ::User.support_bot) }
  scope :inc_relations_for_view, -> { includes(author: :status, assignees: :status) }

  # An issue can be uniquely identified by project_id and iid
  # Takes one or more sets of composite IDs, expressed as hash-like records of
  # `{project_id: x, iid: y}`.
  #
  # @see WhereComposite::where_composite
  #
  # e.g:
  #
  #   .by_project_id_and_iid({project_id: 1, iid: 2})
  #   .by_project_id_and_iid([]) # returns ActiveRecord::NullRelation
  #   .by_project_id_and_iid([
  #     {project_id: 1, iid: 1},
  #     {project_id: 2, iid: 1},
  #     {project_id: 1, iid: 2}
  #   ])
  #
  scope :by_project_id_and_iid, ->(composites) do
    where_composite(%i[project_id iid], composites)
  end

  after_commit :expire_etag_cache, unless: :importing?
  after_save :ensure_metrics, unless: :importing?
  after_create_commit :record_create_action, unless: :importing?

  attr_spammable :title, spam_title: true
  attr_spammable :description, spam_description: true

  state_machine :state_id, initial: :opened, initialize: false do
    event :close do
      transition [:opened] => :closed
    end

    event :reopen do
      transition closed: :opened
    end

    state :opened, value: Issue.available_states[:opened]
    state :closed, value: Issue.available_states[:closed]

    before_transition any => :closed do |issue, transition|
      args = transition.args

      issue.closed_at = issue.system_note_timestamp

      next if args.empty?

      next unless args.first.is_a?(User)

      issue.closed_by = args.first
    end

    before_transition closed: :opened do |issue|
      issue.closed_at = nil
      issue.closed_by = nil
    end
  end

  # Alias to state machine .with_state_id method
  # This needs to be defined after the state machine block to avoid errors
  class << self
    alias_method :with_state, :with_state_id
    alias_method :with_states, :with_state_ids
  end

  def self.relative_positioning_query_base(issue)
    projects = issue.project.group&.root_ancestor&.all_projects || issue.project
    in_projects(projects)
  end

  def self.relative_positioning_parent_column
    :project_id
  end

  def self.reference_prefix
    '#'
  end

  # Pattern used to extract `#123` issue references from text
  #
  # This pattern supports cross-project references.
  def self.reference_pattern
    @reference_pattern ||= %r{
      (#{Project.reference_pattern})?
      #{Regexp.escape(reference_prefix)}#{Gitlab::Regex.issue}
    }x
  end

  def self.link_reference_pattern
    @link_reference_pattern ||= super("issues", Gitlab::Regex.issue)
  end

  def self.reference_valid?(reference)
    reference.to_i > 0 && reference.to_i <= Gitlab::Database::MAX_INT_VALUE
  end

  def self.project_foreign_key
    'project_id'
  end

  def self.simple_sorts
    super.merge(
      {
        'closest_future_date' => -> { order_closest_future_date },
        'closest_future_date_asc' => -> { order_closest_future_date },
        'due_date' => -> { order_due_date_asc.with_order_id_desc },
        'due_date_asc' => -> { order_due_date_asc.with_order_id_desc },
        'due_date_desc' => -> { order_due_date_desc.with_order_id_desc },
        'relative_position' => -> { order_relative_position_asc.with_order_id_desc },
        'relative_position_asc' => -> { order_relative_position_asc.with_order_id_desc }
      }
    )
  end

  def self.sort_by_attribute(method, excluded_labels: [])
    case method.to_s
    when 'closest_future_date', 'closest_future_date_asc' then order_closest_future_date
    when 'due_date', 'due_date_asc'                       then order_due_date_asc.with_order_id_desc
    when 'due_date_desc'                                  then order_due_date_desc.with_order_id_desc
    when 'relative_position', 'relative_position_asc'     then order_relative_position_asc.with_order_id_desc
    when 'severity_asc'                                   then order_severity_asc.with_order_id_desc
    when 'severity_desc'                                  then order_severity_desc.with_order_id_desc
    else
      super
    end
  end

  # `with_cte` argument allows sorting when using CTE queries and prevents
  # errors in postgres when using CTE search optimisation
  def self.order_by_position_and_priority(with_cte: false)
    order_labels_priority(with_cte: with_cte)
      .reorder(Gitlab::Database.nulls_last_order('relative_position', 'ASC'),
              Gitlab::Database.nulls_last_order('highest_priority', 'ASC'),
              "id DESC")
  end

  # Temporary disable moving null elements because of performance problems
  # For more information check https://gitlab.com/gitlab-com/gl-infra/production/-/issues/4321
  def check_repositioning_allowed!
    if blocked_for_repositioning?
      raise ::Gitlab::RelativePositioning::IssuePositioningDisabled, "Issue relative position changes temporarily disabled."
    end
  end

  def blocked_for_repositioning?
    resource_parent.root_namespace&.issue_repositioning_disabled?
  end

  def hook_attrs
    Gitlab::HookData::IssueBuilder.new(self).build
  end

  # `from` argument can be a Namespace or Project.
  def to_reference(from = nil, full: false)
    reference = "#{self.class.reference_prefix}#{iid}"

    "#{project.to_reference_base(from, full: full)}#{reference}"
  end

  def suggested_branch_name
    return to_branch_name unless project.repository.branch_exists?(to_branch_name)

    start_counting_from = 2
    Uniquify.new(start_counting_from).string(-> (counter) { "#{to_branch_name}-#{counter}" }) do |suggested_branch_name|
      project.repository.branch_exists?(suggested_branch_name)
    end
  end

  # Returns boolean if a related branch exists for the current issue
  # ignores merge requests branchs
  def has_related_branch?
    project.repository.branch_names.any? do |branch|
      /\A#{iid}-(?!\d+-stable)/i =~ branch
    end
  end

  # To allow polymorphism with MergeRequest.
  def source_project
    project
  end

  def moved?
    !moved_to_id.nil?
  end

  def duplicated?
    !duplicated_to_id.nil?
  end

  def can_move?(user, to_project = nil)
    if to_project
      return false unless user.can?(:admin_issue, to_project)
    end

    !moved? && persisted? &&
      user.can?(:admin_issue, self.project)
  end
  alias_method :can_clone?, :can_move?

  def to_branch_name
    if self.confidential?
      "#{iid}-confidential-issue"
    else
      branch_name = "#{iid}-#{title.parameterize}"

      if branch_name.length > 100
        truncated_string = branch_name[0, 100]
        # Delete everything dangling after the last hyphen so as not to risk
        # existence of unintended words in the branch name due to mid-word split.
        branch_name = truncated_string[0, truncated_string.rindex("-")]
      end

      branch_name
    end
  end

  def related_issues(current_user, preload: nil)
    related_issues = ::Issue
                       .select(['issues.*', 'issue_links.id AS issue_link_id',
                                'issue_links.link_type as issue_link_type_value',
                                'issue_links.target_id as issue_link_source_id',
                                'issue_links.created_at as issue_link_created_at',
                                'issue_links.updated_at as issue_link_updated_at'])
                       .joins("INNER JOIN issue_links ON
	                             (issue_links.source_id = issues.id AND issue_links.target_id = #{id})
	                             OR
	                             (issue_links.target_id = issues.id AND issue_links.source_id = #{id})")
                       .preload(preload)
                       .reorder('issue_link_id')

    related_issues = yield related_issues if block_given?

    cross_project_filter = -> (issues) { issues.where(project: project) }
    Ability.issues_readable_by_user(related_issues,
      current_user,
      filters: { read_cross_project: cross_project_filter })
  end

  def can_be_worked_on?
    !self.closed? && !self.project.forked?
  end

  # Returns `true` if the current issue can be viewed by either a logged in User
  # or an anonymous user.
  def visible_to_user?(user = nil)
    return false unless project && project.feature_available?(:issues, user)

    return publicly_visible? unless user

    return false unless readable_by?(user)

    user.can_read_all_resources? ||
      ::Gitlab::ExternalAuthorization.access_allowed?(
        user, project.external_authorization_classification_label)
  end

  def check_for_spam?
    publicly_visible? &&
      (title_changed? || description_changed? || confidential_changed?)
  end

  def as_json(options = {})
    super(options).tap do |json|
      if options.key?(:labels)
        json[:labels] = labels.as_json(
          project: project,
          only: [:id, :title, :description, :color, :priority],
          methods: [:text_color]
        )
      end
    end
  end

  def etag_caching_enabled?
    true
  end

  def discussions_rendered_on_frontend?
    true
  end

  # rubocop: disable CodeReuse/ServiceClass
  def update_project_counter_caches
    Projects::OpenIssuesCountService.new(project).refresh_cache
  end
  # rubocop: enable CodeReuse/ServiceClass

  def merge_requests_count(user = nil)
    ::MergeRequestsClosingIssues.count_for_issue(self.id, user)
  end

  def labels_hook_attrs
    labels.map(&:hook_attrs)
  end

  def previous_updated_at
    previous_changes['updated_at']&.first || updated_at
  end

  def banzai_render_context(field)
    super.merge(label_url_method: :project_issues_url)
  end

  def design_collection
    @design_collection ||= ::DesignManagement::DesignCollection.new(self)
  end

  def from_service_desk?
    author.id == User.support_bot.id
  end

  def issue_link_type
    return unless respond_to?(:issue_link_type_value) && respond_to?(:issue_link_source_id)

    type = IssueLink.link_types.key(issue_link_type_value) || IssueLink::TYPE_RELATES_TO
    return type if issue_link_source_id == id

    IssueLink.inverse_link_type(type)
  end

  def relocation_target
    moved_to || duplicated_to
  end

  def supports_assignee?
    issue_type_supports?(:assignee)
  end

  def supports_time_tracking?
    issue_type_supports?(:time_tracking)
  end

  def email_participants_emails
    issue_email_participants.pluck(:email)
  end

  def email_participants_emails_downcase
    issue_email_participants.pluck(IssueEmailParticipant.arel_table[:email].lower)
  end

  def issue_assignee_user_ids
    issue_assignees.pluck(:user_id)
  end

  private

  # Ensure that the metrics association is safely created and respecting the unique constraint on issue_id
  override :ensure_metrics
  def ensure_metrics
    if !association(:metrics).loaded? || metrics.blank?
      metrics_record = Issue::Metrics.safe_find_or_create_by(issue: self)
      self.metrics = metrics_record
    end

    metrics.record!
  end

  def record_create_action
    Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_created_action(author: author)
  end

  # Returns `true` if the given User can read the current Issue.
  #
  # This method duplicates the same check of issue_policy.rb
  # for performance reasons, check commit: 002ad215818450d2cbbc5fa065850a953dc7ada8
  # Make sure to sync this method with issue_policy.rb
  def readable_by?(user)
    if user.can_read_all_resources?
      true
    elsif project.owner == user
      true
    elsif confidential? && !assignee_or_author?(user)
      project.team.member?(user, Gitlab::Access::REPORTER)
    else
      project.public? ||
        project.internal? && !user.external? ||
        project.team.member?(user)
    end
  end

  # Returns `true` if this Issue is visible to everybody.
  def publicly_visible?
    project.public? && !confidential? && !::Gitlab::ExternalAuthorization.enabled?
  end

  def expire_etag_cache
    key = Gitlab::Routing.url_helpers.realtime_changes_project_issue_path(project, self)
    Gitlab::EtagCaching::Store.new.touch(key)
  end

  def could_not_move(exception)
    # Symptom of running out of space - schedule rebalancing
    IssueRebalancingWorker.perform_async(nil, *project.self_or_root_group_ids)
  end
end

Issue.prepend_mod_with('Issue')
