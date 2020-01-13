# frozen_string_literal: true

module Users
  class UpdateService < BaseService
    include NewUserNotifier
    attr_reader :user, :identity_params

    def initialize(current_user, params = {})
      @current_user = current_user
      @user = params.delete(:user)
      @status_params = params.delete(:status)
      @identity_params = params.slice(*identity_attributes)
      @params = params.dup
    end

    def execute(validate: true, &block)
      yield(@user) if block_given?

      user_exists = @user.persisted?

      discard_read_only_attributes
      assign_attributes
      assign_identity

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

    def discard_read_only_attributes
      discard_synced_attributes
      discard_name unless name_updatable?
    end

    def discard_synced_attributes
      if (metadata = @user.user_synced_attributes_metadata)
        read_only = metadata.read_only_attributes

        params.reject! { |key, _| read_only.include?(key.to_sym) }
      end
    end

    def discard_name
      params.delete(:name)
    end

    def name_updatable?
      can?(current_user, :update_name, @user)
    end

    def assign_attributes
      @user.assign_attributes(params.except(*identity_attributes)) unless params.empty?
    end

    def assign_identity
      return unless identity_params.present?

      identity = user.identities.find_or_create_by(provider_params) # rubocop: disable CodeReuse/ActiveRecord
      identity.update(identity_params)
    end

    def identity_attributes
      [:provider, :extern_uid]
    end

    def provider_attributes
      [:provider]
    end

    def provider_params
      identity_params.slice(*provider_attributes)
    end
  end
end

Users::UpdateService.prepend_if_ee('EE::Users::UpdateService')
