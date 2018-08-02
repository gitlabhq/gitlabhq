# frozen_string_literal: true

module Users
  class UpdateService < BaseService
    include NewUserNotifier
    prepend EE::Users::UpdateService

    def initialize(current_user, params = {})
      @current_user = current_user
      @user = params.delete(:user)
      @status_params = params.delete(:status)
      @params = params.dup
    end

    def execute(validate: true, &block)
      yield(@user) if block_given?

      user_exists = @user.persisted?

      assign_attributes(&block)

      if @user.save(validate: validate) && update_status
        notify_success(user_exists)
      else
        messages = @user.errors.full_messages + Array(@user.status&.errors&.full_messages)
        error(messages.uniq.join('. '))
      end
    end

    def execute!(*args, &block)
      result = execute(*args, &block)

      raise ActiveRecord::RecordInvalid.new(@user) unless result[:status] == :success

      true
    end

    private

    def update_status
      return true unless @status_params

      Users::SetStatusService.new(current_user, @status_params.merge(user: @user)).execute
    end

    def notify_success(user_exists)
      notify_new_user(@user, nil) unless user_exists

      success
    end

    def assign_attributes(&block)
      if @user.user_synced_attributes_metadata
        params.except!(*@user.user_synced_attributes_metadata.read_only_attributes)
      end

      @user.assign_attributes(params) if params.any?
    end
  end
end
