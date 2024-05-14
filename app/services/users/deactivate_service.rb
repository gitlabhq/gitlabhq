# frozen_string_literal: true

module Users
  class DeactivateService < BaseService
    def initialize(current_user, skip_authorization: false)
      @current_user = current_user
      @skip_authorization = skip_authorization
    end

    def execute(user)
      unless allowed?
        return ::ServiceResponse.error(message: _('You are not authorized to perform this action'),
          reason: :forbidden)
      end

      if user.blocked?
        return ::ServiceResponse.error(message: _('Error occurred. A blocked user cannot be deactivated'),
          reason: :forbidden)
      end

      if user.internal?
        return ::ServiceResponse.error(message: _('Internal users cannot be deactivated'),
          reason: :forbidden)
      end

      return ::ServiceResponse.success(message: _('User has already been deactivated')) if user.deactivated?

      unless user.can_be_deactivated?
        message = _(
          'The user you are trying to deactivate has been active in the past %{minimum_inactive_days} days ' \
          'and cannot be deactivated')

        deactivation_error_message = format(message,
          minimum_inactive_days: Gitlab::CurrentSettings.deactivate_dormant_users_period)
        return ::ServiceResponse.error(message: deactivation_error_message, reason: :forbidden)
      end

      unless user.deactivate
        return ::ServiceResponse.error(message: user.errors.full_messages.to_sentence,
          reason: :bad_request)
      end

      log_event(user)

      ::ServiceResponse.success
    end

    private

    attr_reader :current_user

    def allowed?
      return true if @skip_authorization

      can?(current_user, :admin_all_resources)
    end

    def log_event(user)
      Gitlab::AppLogger.info(
        message: 'User deactivated',
        username: user.username.to_s,
        user_id: user.id,
        email: user.email.to_s,
        deactivated_by: current_user.username.to_s,
        ip_address: current_user.current_sign_in_ip.to_s
      )
    end
  end
end

Users::DeactivateService.prepend_mod_with('Users::DeactivateService')
