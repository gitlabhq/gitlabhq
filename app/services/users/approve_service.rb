# frozen_string_literal: true

module Users
  class ApproveService < BaseService
    def initialize(current_user)
      @current_user = current_user
    end

    def execute(user)
      return error(_('You are not allowed to approve a user')) unless allowed?
      return error(_('The user you are trying to approve is not pending an approval')) unless approval_required?(user)

      if user.activate
        # Resends confirmation email if the user isn't confirmed yet.
        # Please see Devise's implementation of `resend_confirmation_instructions` for detail.
        user.resend_confirmation_instructions
        user.accept_pending_invitations! if user.active_for_authentication?
        DeviseMailer.user_admin_approval(user).deliver_later

        success
      else
        error(user.errors.full_messages.uniq.join('. '))
      end
    end

    private

    attr_reader :current_user

    def allowed?
      can?(current_user, :approve_user)
    end

    def approval_required?(user)
      user.blocked_pending_approval?
    end
  end
end
