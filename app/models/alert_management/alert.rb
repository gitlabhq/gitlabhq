# frozen_string_literal: true

require_dependency 'alert_management'

module AlertManagement
  class Alert < ApplicationRecord
    include IidRoutes
    include AtomicInternalId
    include ShaAttribute
    include Sortable
    include Noteable
    include Gitlab::SQL::Pattern
    include Presentable
    include Gitlab::Utils::StrongMemoize
    include Referable

    STATUSES = {
      triggered: 0,
      acknowledged: 1,
      resolved: 2,
      ignored: 3
    }.freeze

    STATUS_DESCRIPTIONS = {
      triggered: 'Investigation has not started',
      acknowledged: 'Someone is actively investigating the problem',
      resolved: 'No further work is required',
      ignored: 'No action will be taken on the alert'
    }.freeze

    belongs_to :project
    belongs_to :issue, optional: true
    belongs_to :prometheus_alert, optional: true
    belongs_to :environment, optional: true

    has_many :alert_assignees, inverse_of: :alert
    has_many :assignees, through: :alert_assignees

    has_many :notes, as: :noteable, inverse_of: :noteable, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
    has_many :ordered_notes, -> { fresh }, as: :noteable, class_name: 'Note'
    has_many :user_mentions, class_name: 'AlertManagement::AlertUserMention', foreign_key: :alert_management_alert_id

    has_internal_id :iid, scope: :project

    sha_attribute :fingerprint

    TITLE_MAX_LENGTH = 200
    DESCRIPTION_MAX_LENGTH = 1_000
    SERVICE_MAX_LENGTH = 100
    TOOL_MAX_LENGTH = 100
    HOSTS_MAX_LENGTH = 255

    validates :title,           length: { maximum: TITLE_MAX_LENGTH }, presence: true
    validates :description,     length: { maximum: DESCRIPTION_MAX_LENGTH }
    validates :service,         length: { maximum: SERVICE_MAX_LENGTH }
    validates :monitoring_tool, length: { maximum: TOOL_MAX_LENGTH }
    validates :project,         presence: true
    validates :events,          presence: true
    validates :severity,        presence: true
    validates :status,          presence: true
    validates :started_at,      presence: true
    validates :fingerprint,     allow_blank: true, uniqueness: {
      scope: :project,
      conditions: -> { not_resolved },
      message: -> (object, data) { _('Cannot have multiple unresolved alerts') }
    }, unless: :resolved?
    validate :hosts_format

    enum severity: {
      critical: 0,
      high: 1,
      medium: 2,
      low: 3,
      info: 4,
      unknown: 5
    }

    enum domain: {
      operations: 0,
      threat_monitoring: 1
    }

    state_machine :status, initial: :triggered do
      state :triggered, value: STATUSES[:triggered]

      state :acknowledged, value: STATUSES[:acknowledged]

      state :resolved, value: STATUSES[:resolved] do
        validates :ended_at, presence: true
      end

      state :ignored, value: STATUSES[:ignored]

      state :triggered, :acknowledged, :ignored do
        validates :ended_at, absence: true
      end

      event :trigger do
        transition any => :triggered
      end

      event :acknowledge do
        transition any => :acknowledged
      end

      event :resolve do
        transition any => :resolved
      end

      event :ignore do
        transition any => :ignored
      end

      before_transition to: [:triggered, :acknowledged, :ignored] do |alert, _transition|
        alert.ended_at = nil
      end

      before_transition to: :resolved do |alert, transition|
        ended_at = transition.args.first
        alert.ended_at = ended_at || Time.current
      end
    end

    delegate :iid, to: :issue, prefix: true, allow_nil: true
    delegate :details_url, to: :present

    scope :for_iid, -> (iid) { where(iid: iid) }
    scope :for_status, -> (status) { with_status(status) }
    scope :for_fingerprint, -> (project, fingerprint) { where(project: project, fingerprint: fingerprint) }
    scope :for_environment, -> (environment) { where(environment: environment) }
    scope :for_assignee_username, -> (assignee_username) { joins(:assignees).merge(User.by_username(assignee_username)) }
    scope :search, -> (query) { fuzzy_search(query, [:title, :description, :monitoring_tool, :service]) }
    scope :open, -> { with_status(open_statuses) }
    scope :not_resolved, -> { without_status(:resolved) }
    scope :with_prometheus_alert, -> { includes(:prometheus_alert) }
    scope :with_threat_monitoring_alerts, -> { where(domain: :threat_monitoring ) }
    scope :with_operations_alerts, -> { where(domain: :operations) }

    scope :order_start_time,    -> (sort_order) { order(started_at: sort_order) }
    scope :order_end_time,      -> (sort_order) { order(ended_at: sort_order) }
    scope :order_event_count,   -> (sort_order) { order(events: sort_order) }

    # Ascending sort order sorts severity from less critical to more critical.
    # Descending sort order sorts severity from more critical to less critical.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/221242#what-is-the-expected-correct-behavior
    scope :order_severity,      -> (sort_order) { order(severity: sort_order == :asc ? :desc : :asc) }
    scope :order_severity_with_open_prometheus_alert, -> { open.with_prometheus_alert.order(severity: :asc, started_at: :desc) }

    # Ascending sort order sorts statuses: Ignored > Resolved > Acknowledged > Triggered
    # Descending sort order sorts statuses: Triggered > Acknowledged > Resolved > Ignored
    # https://gitlab.com/gitlab-org/gitlab/-/issues/221242#what-is-the-expected-correct-behavior
    scope :order_status, -> (sort_order) { order(status: sort_order == :asc ? :desc : :asc) }

    scope :counts_by_project_id, -> { group(:project_id).count }

    alias_method :state, :status_name

    def self.state_machine_statuses
      @state_machine_statuses ||= state_machines[:status].states.to_h { |s| [s.name, s.value] }
    end
    private_class_method :state_machine_statuses

    def self.status_value(name)
      state_machine_statuses[name]
    end

    def self.status_name(raw_status)
      state_machine_statuses.key(raw_status)
    end

    def self.counts_by_status
      group(:status).count.transform_keys { |k| status_name(k) }
    end

    def self.status_names
      @status_names ||= state_machine_statuses.keys
    end

    def self.sort_by_attribute(method)
      case method.to_s
      when 'started_at_asc'     then order_start_time(:asc)
      when 'started_at_desc'    then order_start_time(:desc)
      when 'ended_at_asc'       then order_end_time(:asc)
      when 'ended_at_desc'      then order_end_time(:desc)
      when 'event_count_asc'    then order_event_count(:asc)
      when 'event_count_desc'   then order_event_count(:desc)
      when 'severity_asc'       then order_severity(:asc)
      when 'severity_desc'      then order_severity(:desc)
      when 'status_asc'         then order_status(:asc)
      when 'status_desc'        then order_status(:desc)
      else
        order_by(method)
      end
    end

    def self.last_prometheus_alert_by_project_id
      ids = select(arel_table[:id].maximum).group(:project_id)
      with_prometheus_alert.where(id: ids)
    end

    def self.reference_prefix
      '^alert#'
    end

    def self.reference_pattern
      @reference_pattern ||= %r{
        (#{Project.reference_pattern})?
        #{Regexp.escape(reference_prefix)}(?<alert>\d+)
      }x
    end

    def self.link_reference_pattern
      @link_reference_pattern ||= super("alert_management", %r{(?<alert>\d+)/details(\#)?})
    end

    def self.reference_valid?(reference)
      reference.to_i > 0 && reference.to_i <= Gitlab::Database::MAX_INT_VALUE
    end

    def self.open_statuses
      [:triggered, :acknowledged]
    end

    def self.open_status?(status)
      open_statuses.include?(status)
    end

    def open?
      self.class.open_status?(status_name)
    end

    def status_event_for(status)
      self.class.state_machines[:status].events.transitions_for(self, to: status.to_s.to_sym).first&.event
    end

    def change_status_to(new_status)
      event = status_event_for(new_status)
      event && fire_status_event(event)
    end

    def prometheus?
      monitoring_tool == Gitlab::AlertManagement::Payload::MONITORING_TOOLS[:prometheus]
    end

    def register_new_event!
      increment!(:events)
    end

    def to_reference(from = nil, full: false)
      reference = "#{self.class.reference_prefix}#{iid}"

      "#{project.to_reference_base(from, full: full)}#{reference}"
    end

    def execute_integrations
      return unless project.has_active_integrations?(:alert_hooks)

      project.execute_integrations(hook_data, :alert_hooks)
    end

    # Representation of the alert's payload. Avoid accessing
    # #payload attribute directly.
    def parsed_payload
      strong_memoize(:parsed_payload) do
        Gitlab::AlertManagement::Payload.parse(project, payload, monitoring_tool: monitoring_tool)
      end
    end

    private

    def hook_data
      Gitlab::DataBuilder::Alert.build(self)
    end

    def hosts_format
      return unless hosts

      errors.add(:hosts, "hosts array is over #{HOSTS_MAX_LENGTH} chars") if hosts.join.length > HOSTS_MAX_LENGTH
      errors.add(:hosts, "hosts array cannot be nested") if hosts.flatten != hosts
    end
  end
end

AlertManagement::Alert.prepend_mod_with('AlertManagement::Alert')
