module IssuableStates
  extend ActiveSupport::Concern

  # The state:string column is being migrated to state_id:integer column
  # This is a temporary hook to populate state_id column with new values
  # and can be removed after the state column is removed.
  included do
    before_save :set_state_id
  end

  def set_state_id
    return if state.nil? || state.empty?

    states_hash = self.class.available_states

    self.state_id = states_hash[state]
  end
end
