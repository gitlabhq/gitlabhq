module Users
  class UpdateService < BaseService
    include EE::Audit::Changes
    include NewUserNotifier

    def initialize(current_user, user, params = {})
      @current_user = current_user
      @user = user
      @params = params.dup
    end

    def execute(validate: true, &block)
      yield(@user) if block_given?

      assign_attributes(&block)

      user_exists = @user.persisted?

      if @user.save(validate: validate)
        audit_changes(:email, as: 'email address', column: :notification_email)
        audit_changes(:encrypted_password, as: 'password', skip_changes: true)

        notify_new_user(@user, nil) unless user_exists

        success
      else
        error(@user.errors.full_messages.uniq.join('. '))
      end
    end

    def execute!(*args, &block)
      result = execute(*args, &block)

      raise ActiveRecord::RecordInvalid.new(@user) unless result[:status] == :success

      true
    end

    private

    def assign_attributes(&block)
      if @user.user_synced_attributes_metadata
        params.except!(*@user.user_synced_attributes_metadata.read_only_attributes)
      end

      @user.assign_attributes(params) if params.any?
    end

    def model
      @user
    end
  end
end
