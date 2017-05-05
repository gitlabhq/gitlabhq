module Users
  # Service for creating a new user.
  class CreateService < BaseService
    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params.dup
    end

    def execute(skip_authorization: false)
      user = Users::BuildService.new(current_user, params).execute(skip_authorization: skip_authorization)

      @reset_token = user.generate_reset_token if user.recently_sent_password_reset?

      if user.save
        log_info("User \"#{user.name}\" (#{user.email}) was created")
        notification_service.new_user(user, @reset_token) if @reset_token
        system_hook_service.execute_hooks_for(user, :create)
      end

      user
    end
  end
end
