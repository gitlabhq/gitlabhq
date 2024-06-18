# frozen_string_literal: true

class PrometheusAlertEvent < ApplicationRecord
  include AlertEventLifecycle

  belongs_to :project, optional: false, validate: true, inverse_of: :prometheus_alert_events
  belongs_to :prometheus_alert, optional: false, validate: true, inverse_of: :prometheus_alert_events
  has_and_belongs_to_many :related_issues, class_name: 'Issue', join_table: :issues_prometheus_alert_events # rubocop:disable Rails/HasAndBelongsToMany

  validates :payload_key, uniqueness: { scope: :prometheus_alert_id }
  validates :started_at, presence: true

  delegate :title, :prometheus_metric_id, to: :prometheus_alert

  scope :for_environment, ->(environment) do
    joins(:prometheus_alert).where(prometheus_alerts: { environment_id: environment })
  end

  scope :with_prometheus_alert, -> { includes(:prometheus_alert) }

  def self.last_by_project_id
    ids = select(arel_table[:id].maximum.as('id')).group(:project_id).map(&:id)
    with_prometheus_alert.find(ids)
  end

  def self.find_or_initialize_by_payload_key(project, alert, payload_key)
    find_or_initialize_by(project: project, prometheus_alert: alert, payload_key: payload_key)
  end

  def self.find_by_payload_key(payload_key)
    find_by(payload_key: payload_key)
  end

  def self.status_value_for(name)
    state_machines[:status].states[name].value
  end
end
