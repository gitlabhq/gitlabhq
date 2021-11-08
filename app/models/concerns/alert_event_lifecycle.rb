# frozen_string_literal: true

module AlertEventLifecycle
  extend ActiveSupport::Concern

  included do
    validates :started_at, presence: true
    validates :status, presence: true

    state_machine :status, initial: :none do
      state :none, value: nil

      state :firing, value: 0 do
        validates :payload_key, presence: true
        validates :ended_at, absence: true
      end

      state :resolved, value: 1 do
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
        alert_event.ended_at = ended_at || Time.current
      end
    end

    scope :firing, -> { where(status: status_value_for(:firing)) }
    scope :resolved, -> { where(status: status_value_for(:resolved)) }

    def self.status_value_for(name)
      state_machines[:status].states[name].value
    end
  end
end
