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

      if @user.save || !@user.changed?
        success
      else
        error(@user.errors.full_messages.uniq.join('. '))
      end
    end

    def execute!(skip_authorization: false, &block)
      assign_attributes(skip_authorization, &block)

      @user.save! if @user.changed?
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
