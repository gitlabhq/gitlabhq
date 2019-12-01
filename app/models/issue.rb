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

  DueDateStruct                   = Struct.new(:title, :name).freeze
  NoDueDate                       = DueDateStruct.new('No Due Date', '0').freeze
  AnyDueDate                      = DueDateStruct.new('Any Due Date', '').freeze
  Overdue                         = DueDateStruct.new('Overdue', 'overdue').freeze
  DueThisWeek                     = DueDateStruct.new('Due This Week', 'week').freeze
  DueThisMonth                    = DueDateStruct.new('Due This Month', 'month').freeze
  DueNextMonthAndPreviousTwoWeeks = DueDateStruct.new('Due Next Month And Previous Two Weeks', 'next_month_and_previous_two_weeks').freeze

  SORTING_PREFERENCE_FIELD = :issues_sort

  belongs_to :project
  belongs_to :moved_to, class_name: 'Issue'
  belongs_to :duplicated_to, class_name: 'Issue'
  belongs_to :closed_by, class_name: 'User'

  has_internal_id :iid, scope: :project, init: ->(s) { s&.project&.issues&.maximum(:iid) }

  has_many :events, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  has_many :merge_requests_closing_issues,
    class_name: 'MergeRequestsClosingIssues',
    dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  has_many :issue_assignees
  has_many :assignees, class_name: "User", through: :issue_assignees
  has_many :zoom_meetings

  validates :project, presence: true

  alias_attribute :parent_ids, :project_id
  alias_method :issuing_parent, :project

  scope :in_projects, ->(project_ids) { where(project_id: project_ids) }

  scope :with_due_date, -> { where.not(due_date: nil) }
  scope :without_due_date, -> { where(due_date: nil) }
  scope :due_before, ->(date) { where('issues.due_date < ?', date) }
  scope :due_between, ->(from_date, to_date) { where('issues.due_date >= ?', from_date).where('issues.due_date <= ?', to_date) }
  scope :due_tomorrow, -> { where(due_date: Date.tomorrow) }

  scope :order_due_date_asc, -> { reorder(::Gitlab::Database.nulls_last_order('due_date', 'ASC')) }
  scope :order_due_date_desc, -> { reorder(::Gitlab::Database.nulls_last_order('due_date', 'DESC')) }
  scope :order_closest_future_date, -> { reorder(Arel.sql('CASE WHEN issues.due_date >= CURRENT_DATE THEN 0 ELSE 1 END ASC, ABS(CURRENT_DATE - issues.due_date) ASC')) }
  scope :order_relative_position_asc, -> { reorder(::Gitlab::Database.nulls_last_order('relative_position', 'ASC')) }

  scope :preload_associated_models, -> { preload(:labels, project: :namespace) }
  scope :with_api_entity_associations, -> { preload(:timelogs, :assignees, :author, :notes, :labels, project: [:route, { namespace: :route }] ) }

  scope :public_only, -> { where(confidential: false) }
  scope :confidential_only, -> { where(confidential: true) }

  scope :counts_by_state, -> { reorder(nil).group(:state_id).count }

  ignore_column :state, remove_with: '12.7', remove_after: '2019-12-22'

  after_commit :expire_etag_cache
  after_save :ensure_metrics, unless: :imported?

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

    before_transition any => :closed do |issue|
      issue.closed_at = issue.system_note_timestamp
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
    in_projects(issue.parent_ids)
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
      #{Regexp.escape(reference_prefix)}(?<issue>\d+)
    }x
  end

  def self.link_reference_pattern
    @link_reference_pattern ||= super("issues", /(?<issue>\d+)/)
  end

  def self.reference_valid?(reference)
    reference.to_i > 0 && reference.to_i <= Gitlab::Database::MAX_INT_VALUE
  end

  def self.project_foreign_key
    'project_id'
  end

  def self.sort_by_attribute(method, excluded_labels: [])
    case method.to_s
    when 'closest_future_date', 'closest_future_date_asc' then order_closest_future_date
    when 'due_date', 'due_date_asc'                       then order_due_date_asc.with_order_id_desc
    when 'due_date_desc'                                  then order_due_date_desc.with_order_id_desc
    when 'relative_position', 'relative_position_asc'     then order_relative_position_asc.with_order_id_desc
    else
      super
    end
  end

  def self.order_by_position_and_priority
    order_labels_priority
      .reorder(Gitlab::Database.nulls_last_order('relative_position', 'ASC'),
              Gitlab::Database.nulls_last_order('highest_priority', 'ASC'),
              "id DESC")
  end

  def hook_attrs
    Gitlab::HookData::IssueBuilder.new(self).build
  end

  # `from` argument can be a Namespace or Project.
  def to_reference(from = nil, full: false)
    reference = "#{self.class.reference_prefix}#{iid}"

    "#{project.to_reference(from, full: full)}#{reference}"
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

  def can_be_worked_on?
    !self.closed? && !self.project.forked?
  end

  # Returns `true` if the current issue can be viewed by either a logged in User
  # or an anonymous user.
  def visible_to_user?(user = nil)
    return false unless project && project.feature_available?(:issues, user)

    return publicly_visible? unless user

    return false unless readable_by?(user)

    user.full_private_access? ||
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

  private

  def ensure_metrics
    super
    metrics.record!
  end

  # Returns `true` if the given User can read the current Issue.
  #
  # This method duplicates the same check of issue_policy.rb
  # for performance reasons, check commit: 002ad215818450d2cbbc5fa065850a953dc7ada8
  # Make sure to sync this method with issue_policy.rb
  def readable_by?(user)
    if user.admin?
      true
    elsif project.owner == user
      true
    elsif confidential?
      author == user ||
        assignees.include?(user) ||
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
end

Issue.prepend_if_ee('EE::Issue')
