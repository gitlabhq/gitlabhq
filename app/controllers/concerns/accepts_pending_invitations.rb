# frozen_string_literal: true

module AcceptsPendingInvitations
  extend ActiveSupport::Concern

  def accept_pending_invitations(user: resource)
    return unless user.active_for_authentication?

    if user.pending_invitations.load.any?
      user.accept_pending_invitations!
      clear_stored_location_for(user: user)
      after_pending_invitations_hook
    end
  end

  def after_pending_invitations_hook
    # no-op
  end

  def clear_stored_location_for(user:)
    session_key = stored_location_key_for(user)

    session.delete(session_key)
  end
end
