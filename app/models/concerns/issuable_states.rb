# frozen_string_literal: true

module IssuableStates
  extend ActiveSupport::Concern

  # The state:string column is being migrated to state_id:integer column
  # This is a temporary hook to populate state_id column with new values
  # and should be removed after the state column is removed.
  # Check https://gitlab.com/gitlab-org/gitlab-ce/issues/51789 for more information
  included do
    before_save :set_state_id
  end

  def set_state_id
    return if state.nil? || state.empty?

    # Needed to prevent breaking some migration specs that
    # rollback database to a point where state_id does not exist.
    # We can use this guard clause for now since this file will
    # be removed in the next release.
    return unless self.has_attribute?(:state_id)

    self.state_id = self.class.available_states[state]
  end
end
