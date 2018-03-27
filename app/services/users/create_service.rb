module Users
  class CreateService < BaseService
    include NewUserNotifier

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params.dup
    end

    def execute(skip_authorization: false)
      user = Users::BuildService.new(current_user, params).execute(skip_authorization: skip_authorization)

      @reset_token = user.generate_reset_token if user.recently_sent_password_reset?

      notify_new_user(user, @reset_token) if user.save

      user
    end
  end
end
