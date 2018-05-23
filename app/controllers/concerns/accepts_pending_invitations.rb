module AcceptsPendingInvitations
  extend ActiveSupport::Concern

  def accept_pending_invitations
    return unless resource.active_for_authentication?

    clear_stored_location_for_resource if resource.accept_pending_invitations!.any?
  end

  def clear_stored_location_for_resource
    session_key = stored_location_key_for(resource)

    session.delete(session_key)
  end
end
