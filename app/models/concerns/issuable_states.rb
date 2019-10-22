# frozen_string_literal: true

module IssuableStates
  extend ActiveSupport::Concern

  # The state:string column is being migrated to state_id:integer column
  # This is a temporary hook to keep state column in sync until it is removed.
  # Check https: https://gitlab.com/gitlab-org/gitlab/issues/33814 for more information
  # The state column can be safely removed after 2019-10-27
  included do
    before_save :sync_issuable_deprecated_state
  end

  def sync_issuable_deprecated_state
    return if self.is_a?(Epic)
    return unless respond_to?(:state)
    return if state_id.nil?

    deprecated_state = self.class.available_states.key(state_id)

    self.write_attribute(:state, deprecated_state)
  end
end
