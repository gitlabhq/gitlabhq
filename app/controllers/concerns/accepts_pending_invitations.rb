module AcceptsPendingInvitations
  extend ActiveSupport::Concern

  def accept_pending_invitations_for(resource)
    resource.accept_pending_invitations.each do |accepted_invite_token|
      clear_stored_location_for(resource) if accept_invite_path(id: accepted_invite_token)
    end
  end

  def clear_stored_location_for(resource)
    # by calling stored_location_for devise removes the stored location from the session
    stored_location_for(resource)
  end
end
