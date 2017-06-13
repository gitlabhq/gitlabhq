module Users
  # Service for creating a new user.
  class UpdateService < BaseService
    def initialize(current_user, user, params = {})
      @current_user = current_user
      @user = user
      @params = params.dup
    end

    def execute(skip_authorization: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || can_update_user?

      if @user.update_attributes(params)
        success
      else
        error('Project could not be updated')
      end
    end

    def can_update_user?
      current_user == @user || current_user&.admin?
    end
  end
end
