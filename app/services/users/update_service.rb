module Users
  class UpdateService < BaseService
    include NewUserNotifier
    prepend EE::Users::UpdateService

    def initialize(current_user, params = {})
      @current_user = current_user
      @user = params[:user]
      @params = params.dup
    end

    def execute(validate: true, &block)
      yield(@user) if block_given?

      assign_attributes(&block)

      user_exists = @user.persisted?

      if @user.save(validate: validate)
        notify_success(user_exists)
      else
        error(@user.errors.full_messages.uniq.join('. '))
      end
    end

    def execute!(*args, &block)
      result = execute(*args, &block)

      raise ActiveRecord::RecordInvalid.new(@user) unless result[:status] == :success

      true
    end

    protected

    def notify_success(user_exists)
      notify_new_user(@user, nil) unless user_exists

      success
    end

    private

    def assign_attributes(&block)
      if @user.user_synced_attributes_metadata
        params.except!(*@user.user_synced_attributes_metadata.read_only_attributes)
      end

      @user.assign_attributes(params) if params.any?
    end
  end
end
