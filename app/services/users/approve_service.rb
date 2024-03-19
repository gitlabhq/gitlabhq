# frozen_string_literal: true

module Users
  class ApproveService < BaseService
    def initialize(current_user)
      @current_user = current_user
    end

    def execute(user)
      return error(_('You are not allowed to approve a user'), :forbidden) unless allowed?
      return error(_('The user you are trying to approve is not pending approval'), :conflict) if user.active? || !approval_required?(user)

      if user.activate
        # Resends confirmation email if the user isn't confirmed yet.
        # Please see Devise's implementation of `resend_confirmation_instructions` for detail.
        user.resend_confirmation_instructions
        user.accept_pending_invitations! if user.active_for_authentication?
        DeviseMailer.user_admin_approval(user).deliver_later

        if user.created_by_id
          reset_token = user.generate_reset_token
          NotificationService.new.new_user(user, reset_token)
        end

        log_event(user)
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

    def log_event(user)
      Gitlab::AppLogger.info(
        message: "User instance access request approved",
        username: user.username.to_s,
        user_id: user.id,
        email: user.email.to_s,
        approved_by: current_user.username.to_s,
        ip_address: current_user.current_sign_in_ip.to_s
      )
    end
  end
end

Users::ApproveService.prepend_mod_with('Users::ApproveService')
