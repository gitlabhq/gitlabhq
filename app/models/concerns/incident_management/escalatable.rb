# frozen_string_literal: true

module IncidentManagement
  # Shared functionality for a `#status` field, representing
  # whether action is required. In EE, this corresponds
  # to paging functionality with EscalationPolicies.
  #
  # This module is only responsible for setting the status and
  # possible status-related timestamps (EX triggered_at/resolved_at)
  # for the implementing class. The relationships between these
  # values and other related timestamps/logic should be managed from
  # the object class itself. (EX Alert#ended_at = Alert#resolved_at)
  module Escalatable
    extend ActiveSupport::Concern

    STATUSES = {
      triggered: 0,
      acknowledged: 1,
      resolved: 2,
      ignored: 3
    }.freeze

    STATUS_DESCRIPTIONS = {
      triggered: 'Investigation has not started',
      acknowledged: 'Someone is actively investigating the problem',
      resolved: 'The problem has been addressed',
      ignored: 'No action will be taken'
    }.freeze

    OPEN_STATUSES = [:triggered, :acknowledged].freeze

    included do
      validates :status, presence: true

      # Ascending sort order sorts statuses: Ignored > Resolved > Acknowledged > Triggered
      # Descending sort order sorts statuses: Triggered > Acknowledged > Resolved > Ignored
      # https://gitlab.com/gitlab-org/gitlab/-/issues/221242#what-is-the-expected-correct-behavior
      scope :order_status, ->(sort_order) { order(status: sort_order == :asc ? :desc : :asc) }
      scope :open, -> { with_status(OPEN_STATUSES) }

      state_machine :status, initial: :triggered do
        state :triggered, value: STATUSES[:triggered]

        state :acknowledged, value: STATUSES[:acknowledged]

        state :resolved, value: STATUSES[:resolved] do
          validates :resolved_at, presence: true
        end

        state :ignored, value: STATUSES[:ignored]

        state :triggered, :acknowledged, :ignored do
          validates :resolved_at, absence: true
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

        before_transition to: [:triggered, :acknowledged, :ignored] do |escalatable, _transition|
          escalatable.resolved_at = nil
        end

        before_transition to: :resolved do |escalatable, transition|
          resolved_at = transition.args.first
          escalatable.resolved_at = resolved_at || Time.current
        end
      end

      class << self
        def status_value(name)
          state_machine_statuses[name]
        end

        def status_name(raw_status)
          state_machine_statuses.key(raw_status)
        end

        def status_names
          @status_names ||= state_machine_statuses.keys
        end

        def open_status?(status)
          OPEN_STATUSES.include?(status)
        end

        private

        def state_machine_statuses
          @state_machine_statuses ||= state_machines[:status].states.to_h { |s| [s.name, s.value] }
        end
      end

      def status_event_for(status)
        self.class.state_machines[:status].events.transitions_for(self, to: status.to_s.to_sym).first&.event
      end

      def open?
        self.class.open_status?(status_name)
      end
    end
  end
end

::IncidentManagement::Escalatable.prepend_mod
