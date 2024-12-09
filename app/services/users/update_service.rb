# frozen_string_literal: true

module Users
  class UpdateService < BaseService
    include NewUserNotifier
    include Gitlab::Utils::StrongMemoize

    attr_reader :user, :identity_params

    ATTRS_REQUIRING_PASSWORD_CHECK = %w[email].freeze
    BATCH_SIZE = 100
    ORGANIZATION_USERS_LIMIT = 1 # users can only belong to a single organization for Cells 1.0

    def initialize(current_user, params = {})
      @current_user = current_user
      @validation_password = params.delete(:validation_password)
      @user = params.delete(:user)
      @status_params = params.delete(:status)
      @identity_params = params.slice(*identity_attributes)
      @params = params.dup
    end

    def execute(validate: true, check_password: false, &block)
      return organization_users_error if organization_users_error

      yield(@user) if block

      user_exists = @user.persisted?
      @user.user_detail # prevent assignment

      discard_read_only_attributes
      assign_attributes

      if check_password && require_password_check? && !@user.valid_password?(@validation_password)
        return error(s_("Profiles|Invalid password"))
      end

      assign_identity
      reset_unconfirmed_email

      if @user.save(validate: validate) && update_status
        after_update(user_exists)
      else
        messages = @user.errors.full_messages + Array(@user.status&.errors&.full_messages)
        error(messages.uniq.join('. '))
      end
    end

    def execute!(*args, **kargs, &block)
      result = execute(*args, **kargs, &block)

      raise ActiveRecord::RecordInvalid, @user unless result[:status] == :success

      true
    end

    private

    def organization_users_attributes
      params[:organization_users_attributes] || []
    end

    def error_message(content)
      @user.errors.add(:base, content)
      error(content)
    end

    def organization_ids_invalid_error
      error_message(_('Organization ID cannot be nil'))
    end

    def organization_permission_error
      error_message(_('Insufficient permission to modify user organizations'))
    end

    def organization_users_limit_exceeded_error
      message = format(_('Cannot update more than %{limit} organization data at once'), limit: ORGANIZATION_USERS_LIMIT)
      error_message(message)
    end

    def organization_ids_invalid?
      organization_ids.include?(nil)
    end

    def organization_users_limit_exceeded?
      organization_users_attributes.count > ORGANIZATION_USERS_LIMIT
    end

    def organization_users_error
      return if organization_users_attributes.blank?
      return organization_permission_error unless current_user.can_admin_all_resources?
      return organization_users_limit_exceeded_error if organization_users_limit_exceeded?
      return organization_ids_invalid_error if organization_ids_invalid?

      nil
    end
    strong_memoize_attr :organization_users_error

    def organization_ids
      organization_users_attributes.pluck(:organization_id).uniq # rubocop:disable Database/AvoidUsingPluckWithoutLimit, CodeReuse/ActiveRecord -- Capped to ORGANIZATION_USERS_LIMIT and plucks on an array of plain hashes
    end

    def require_password_check?
      return false unless @user.persisted?
      return false if @user.password_automatically_set?

      changes = @user.changed
      ATTRS_REQUIRING_PASSWORD_CHECK.any? { |param| changes.include?(param) }
    end

    def reset_unconfirmed_email
      return unless @user.persisted?
      return unless @user.email_changed?

      @user.update_column(:unconfirmed_email, nil)
    end

    def update_status
      return true unless @status_params

      Users::SetStatusService.new(current_user, @status_params.merge(user: @user)).execute
    end

    def notify_success(user_exists)
      notify_new_user(@user, nil) unless user_exists
    end

    def discard_read_only_attributes
      discard_synced_attributes
    end

    def discard_synced_attributes
      params.reject! { |key, _| synced_attributes.include?(key.to_sym) }
    end

    def synced_attributes
      if (metadata = @user.user_synced_attributes_metadata)
        metadata.read_only_attributes
      else
        []
      end
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

    def after_update(user_exists)
      notify_success(user_exists)
      remove_followers_and_followee!

      success
    end

    def remove_followers_and_followee!
      return false unless user.user_preference.enabled_following_previously_changed?(from: true, to: false)

      # rubocop: disable CodeReuse/ActiveRecord
      loop do
        inner_query = Users::UserFollowUser
                        .where(follower_id: user.id).or(Users::UserFollowUser.where(followee_id: user.id))
                        .select(:follower_id, :followee_id)
                        .limit(BATCH_SIZE)

        deleted_records = Users::UserFollowUser.where('(follower_id, followee_id) IN (?)', inner_query).delete_all

        break if deleted_records == 0
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end

Users::UpdateService.prepend_mod_with('Users::UpdateService')
