# frozen_string_literal: true

class PrometheusAlert < ApplicationRecord
  include Sortable
  include UsageStatistics
  include Presentable
  include EachBatch

  OPERATORS_MAP = {
    lt: "<",
    eq: "==",
    gt: ">"
  }.freeze

  belongs_to :environment, validate: true, inverse_of: :prometheus_alerts
  belongs_to :project, validate: true, inverse_of: :prometheus_alerts
  belongs_to :prometheus_metric, validate: true, inverse_of: :prometheus_alerts

  has_many :prometheus_alert_events, inverse_of: :prometheus_alert
  has_many :related_issues, through: :prometheus_alert_events
  has_many :alert_management_alerts, class_name: 'AlertManagement::Alert', inverse_of: :prometheus_alert

  after_destroy :clear_prometheus_adapter_cache!
  after_save :clear_prometheus_adapter_cache!

  validates :environment, :project, :prometheus_metric, :threshold, :operator, presence: true
  validates :runbook_url, length: { maximum: 255 }, allow_blank: true,
    addressable_url: { enforce_sanitization: true, ascii_only: true }
  validate :require_valid_environment_project!
  validate :require_valid_metric_project!

  enum operator: { lt: 0, eq: 1, gt: 2 }

  delegate :title, :query, to: :prometheus_metric

  scope :for_metric, ->(metric) { where(prometheus_metric: metric) }
  scope :for_project, ->(project) { where(project_id: project) }
  scope :for_environment, ->(environment) { where(environment_id: environment) }
  scope :get_environment_id, -> { select(:environment_id).pluck(:environment_id) }

  def self.distinct_projects
    sub_query = self.group(:project_id).select(1)
    self.from(sub_query)
  end

  def self.operator_to_enum(op)
    OPERATORS_MAP.invert.fetch(op)
  end

  def full_query
    "#{query} #{computed_operator} #{threshold}"
  end

  def computed_operator
    OPERATORS_MAP.fetch(operator.to_sym)
  end

  def to_param
    {
      "alert" => title,
      "expr" => full_query,
      "for" => "5m",
      "labels" => {
        "gitlab" => "hook",
        "gitlab_alert_id" => prometheus_metric_id,
        "gitlab_prometheus_alert_id" => id
      },
      "annotations" => {
        "runbook" => runbook_url
      }
    }
  end

  private

  def clear_prometheus_adapter_cache!
    environment.clear_prometheus_reactive_cache!(:additional_metrics_environment)
  end

  def require_valid_environment_project!
    return if project == environment&.project

    errors.add(:environment, 'invalid project')
  end

  def require_valid_metric_project!
    return if prometheus_metric&.common?
    return if project == prometheus_metric&.project

    errors.add(:prometheus_metric, 'invalid project')
  end
end
