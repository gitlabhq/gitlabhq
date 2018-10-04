# frozen_string_literal: true

class PrometheusAlertEvent < ActiveRecord::Base
  belongs_to :project, required: true, validate: true, inverse_of: :prometheus_alert_events
  belongs_to :prometheus_alert, required: true, validate: true, inverse_of: :prometheus_alert_events

  validates :payload_key, uniqueness: { scope: :prometheus_alert_id }

  validates :started_at, presence: true
  validates :status, presence: true

  delegate :title, :prometheus_metric_id, to: :prometheus_alert

  state_machine :status, initial: :none do
    state :none, value: nil

    state :firing, value: 0 do
      validates :payload_key, presence: true
      validates :ended_at, absence: true
    end

    state :resolved, value: 1 do
      validates :payload_key, absence: true
      validates :ended_at, presence: true
    end

    event :fire do
      transition none: :firing
    end

    event :resolve do
      transition firing: :resolved
    end

    before_transition to: :firing do |alert_event, transition|
      started_at = transition.args.first
      alert_event.started_at = started_at
    end

    before_transition to: :resolved do |alert_event, transition|
      ended_at = transition.args.first
      alert_event.payload_key = nil
      alert_event.ended_at = ended_at
    end
  end

  scope :firing, -> { where(status: status_value_for(:firing)) }
  scope :resolved, -> { where(status: status_value_for(:resolved)) }

  def self.find_or_initialize_by_payload_key(project, alert, payload_key)
    find_or_initialize_by(project: project, prometheus_alert: alert, payload_key: payload_key)
  end

  def self.status_value_for(name)
    state_machines[:status].states[name].value
  end

  def self.payload_key_for(gitlab_alert_id, started_at)
    plain = [gitlab_alert_id, started_at].join('/')

    Digest::SHA1.hexdigest(plain)
  end
end
