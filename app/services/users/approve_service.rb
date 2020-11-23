# frozen_string_literal: true

module Users
  class ApproveService < BaseService
    def initialize(current_user)
      @current_user = current_user
    end

    def execute(user)
      return error(_('You are not allowed to approve a user'), :forbidden) unless allowed?
      return error(_('The user you are trying to approve is not pending an approval'), :conflict) if user.active?
      return error(_('The user you are trying to approve is not pending an approval'), :conflict) unless approval_required?(user)

      if user.activate
        # Resends confirmation email if the user isn't confirmed yet.
        # Please see Devise's implementation of `resend_confirmation_instructions` for detail.
        user.resend_confirmation_instructions
        user.accept_pending_invitations! if user.active_for_authentication?
        DeviseMailer.user_admin_approval(user).deliver_later

        after_approve_hook(user)
        success(message: 'Success', http_status: :created)
      else
        error(user.errors.full_messages.uniq.join('. '), :unprocessable_entity)
      end
    end

    private

    attr_reader :current_user

    def after_approve_hook(user)
      # overridden by EE module
    end

    def allowed?
      can?(current_user, :approve_user)
    end

    def approval_required?(user)
      user.blocked_pending_approval?
    end
  end
end

Users::ApproveService.prepend_if_ee('EE::Users::ApproveService')
