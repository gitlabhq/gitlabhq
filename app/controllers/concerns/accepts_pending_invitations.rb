# frozen_string_literal: true

module AcceptsPendingInvitations
  extend ActiveSupport::Concern

  def accept_pending_invitations(user: resource)
    return unless user.active_for_authentication?

    if user.pending_invitations.load.any?
      user.accept_pending_invitations!
      after_pending_invitations_hook
    end
  end

  def after_pending_invitations_hook
    # no-op
  end
end
