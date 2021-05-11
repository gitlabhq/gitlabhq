# frozen_string_literal: true

module Users
  class RejectService < BaseService
    def initialize(current_user)
      @current_user = current_user
    end

    def execute(user)
      return error(_('You are not allowed to reject a user')) unless allowed?
      return error(_('This user does not have a pending request')) unless user.blocked_pending_approval?

      user.delete_async(deleted_by: current_user, params: { hard_delete: true })

      after_reject_hook(user)

      NotificationService.new.user_admin_rejection(user.name, user.email)

      log_event(user)

      success
    end

    private

    attr_reader :current_user

    def allowed?
      can?(current_user, :reject_user)
    end

    def after_reject_hook(user)
      # overridden by EE module
    end

    def log_event(user)
      Gitlab::AppLogger.info(message: "User instance access request rejected", user: "#{user.username}", email: "#{user.email}", rejected_by: "#{current_user.username}", ip_address: "#{current_user.current_sign_in_ip}")
    end
  end
end

Users::RejectService.prepend_mod_with('Users::RejectService')
