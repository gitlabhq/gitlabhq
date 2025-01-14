# frozen_string_literal: true

require_dependency 'alert_management'

module AlertManagement
  class Alert < ApplicationRecord
    include IidRoutes
    include AtomicInternalId
    include ShaAttribute
    include Sortable
    include Noteable
    include Mentionable
    include Todoable
    include Gitlab::SQL::Pattern
    include Presentable
    include Gitlab::Utils::StrongMemoize
    include Referable
    include ::IncidentManagement::Escalatable

    ignore_column :prometheus_alert_id, remove_with: '17.6', remove_after: '2024-10-12'

    belongs_to :project
    belongs_to :issue, optional: true
    belongs_to :environment, optional: true

    has_many :alert_assignees, inverse_of: :alert
    has_many :assignees, through: :alert_assignees

    has_many :notes, as: :noteable, inverse_of: :noteable, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
    has_many :ordered_notes, -> { fresh }, as: :noteable, class_name: 'Note', inverse_of: :noteable
    has_many :user_mentions, class_name: 'AlertManagement::AlertUserMention', foreign_key: :alert_management_alert_id,
      inverse_of: :alert
    has_many :metric_images, class_name: '::AlertManagement::MetricImage'

    has_internal_id :iid, scope: :project

    sha_attribute :fingerprint

    # Allow :ended_at to be managed by Escalatable
    alias_attribute :resolved_at, :ended_at

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
    validates :started_at,      presence: true
    validates :fingerprint,     allow_blank: true, uniqueness: {
      scope: :project,
      conditions: -> { not_resolved },
      message: ->(object, data) { _('Cannot have multiple unresolved alerts') }
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

    delegate :iid, to: :issue, prefix: true, allow_nil: true
    delegate :details_url, to: :present

    scope :for_iid, ->(iid) { where(iid: iid) }
    scope :for_fingerprint, ->(project, fingerprint) { where(project: project, fingerprint: fingerprint) }
    scope :for_environment, ->(environment) { where(environment: environment) }
    scope :for_assignee_username, ->(assignee_username) { joins(:assignees).merge(User.by_username(assignee_username)) }
    scope :search, ->(query) { fuzzy_search(query, [:title, :description, :monitoring_tool, :service]) }
    scope :not_resolved, -> { without_status(:resolved) }
    scope :with_operations_alerts, -> { where(domain: :operations) }

    scope :order_start_time,    ->(sort_order) { order(started_at: sort_order) }
    scope :order_end_time,      ->(sort_order) { order(ended_at: sort_order) }
    scope :order_event_count,   ->(sort_order) { order(events: sort_order) }

    # Ascending sort order sorts severity from less critical to more critical.
    # Descending sort order sorts severity from more critical to less critical.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/221242#what-is-the-expected-correct-behavior
    scope :order_severity,      ->(sort_order) { order(severity: sort_order == :asc ? :desc : :asc) }
    scope :open_order_by_severity, -> { open.order(severity: :asc, started_at: :desc) }

    scope :counts_by_project_id, -> { group(:project_id).count }

    alias_method :state, :status_name

    def self.counts_by_status
      group(:status).count.transform_keys { |k| status_name(k) }
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

    def self.find_unresolved_alert(project, fingerprint)
      for_fingerprint(project, fingerprint).not_resolved.take
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
      pattern = %r{(?<alert>\d+)/details(?:\#)?}
      @link_reference_pattern ||= compose_link_reference_pattern('alert_management', pattern)
    end

    def self.reference_valid?(reference)
      reference.to_i > 0 && reference.to_i <= Gitlab::Database::MAX_INT_VALUE
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

    def to_ability_name
      'alert_management_alert'
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
