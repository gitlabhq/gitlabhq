# frozen_string_literal: true

module AcceptsPendingInvitations
  extend ActiveSupport::Concern

  def accept_pending_invitations
    return unless resource.active_for_authentication?

    if resource.pending_invitations.load.any?
      resource.accept_pending_invitations!
      clear_stored_location_for_resource
      after_pending_invitations_hook
    end
  end

  def after_pending_invitations_hook
    # no-op
  end

  def clear_stored_location_for_resource
    session_key = stored_location_key_for(resource)

    session.delete(session_key)
  end
end
