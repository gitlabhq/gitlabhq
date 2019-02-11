# frozen_string_literal: true

# == IssuableStates concern
#
# Defines statuses shared by issuables which are persisted on state column
# using the state machine.
#
# Used by EE::Epic, Issue and MergeRequest
#
module IssuableStates
  extend ActiveSupport::Concern

  # Override this constant on model where different states are needed
  # Check MergeRequest::AVAILABLE_STATES
  AVAILABLE_STATES = { opened: 1, closed: 2 }.freeze

  included do
    before_save :set_state_id
  end

  class_methods do
    def states
      @states ||= OpenStruct.new(self::AVAILABLE_STATES)
    end
  end

  # The state:string column is being migrated to state_id:integer column
  # This is a temporary hook to populate state_id column with new values
  # and can be removed after the complete migration is done.
  def set_state_id
    return if state.nil? || state.empty?

    states_hash = self.class.states.to_h.with_indifferent_access

    self.state_id = states_hash[state]
  end
end
