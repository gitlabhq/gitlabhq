# frozen_string_literal: true

module Users
  class DestroySessionService
    attr_reader :current_user, :user, :private_session_id

    def initialize(current_user:, user:, private_session_id:)
      @current_user = current_user
      @user = user
      @private_session_id = private_session_id
    end

    def execute
      unless current_user.can_admin_all_resources?
        return ServiceResponse.error(
          message: 'The current user is not authorized to destroy the session',
          reason: :forbidden
        )
      end

      ActiveSession.destroy_session(user, private_session_id)

      ServiceResponse.success
    end
  end
end
