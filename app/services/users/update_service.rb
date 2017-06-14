module Users
  # Service for creating a new user.
  class UpdateService < BaseService
    def initialize(current_user, user, params = {})
      @current_user = current_user
      @user = user
      @params = params.dup
    end

    def execute(skip_authorization: false, &block)
      assign_attributes(skip_authorization, &block)

      if @user.save
        success
      else
        error('User could not be updated')
      end
    end

    def execute!(skip_authorization: false, &block)
      assign_attributes(skip_authorization, &block)

      @user.save!
    end

    private

    def assign_attributes(skip_authorization, &block)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || can_update_user?

      yield(@user) if block_given?

      @user.assign_attributes(params) if params.any?
    end

    def can_update_user?
      current_user == @user || current_user&.admin?
    end
  end
end
