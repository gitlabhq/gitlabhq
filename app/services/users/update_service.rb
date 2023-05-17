# frozen_string_literal: true

module Users
  class UpdateService < BaseService
    include NewUserNotifier
    attr_reader :user, :identity_params

    ATTRS_REQUIRING_PASSWORD_CHECK = %w[email].freeze
    BATCH_SIZE = 100

    def initialize(current_user, params = {})
      @current_user = current_user
      @validation_password = params.delete(:validation_password)
      @user = params.delete(:user)
      @status_params = params.delete(:status)
      @identity_params = params.slice(*identity_attributes)
      @params = params.dup
    end

    def execute(validate: true, check_password: false, &block)
      yield(@user) if block

      user_exists = @user.persisted?
      @user.user_detail # prevent assignment

      discard_read_only_attributes
      assign_attributes

      if check_password && require_password_check? && !@user.valid_password?(@validation_password)
        return error(s_("Profiles|Invalid password"))
      end

      assign_identity
      build_canonical_email
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

    def require_password_check?
      return false unless @user.persisted?
      return false if @user.password_automatically_set?

      changes = @user.changed
      ATTRS_REQUIRING_PASSWORD_CHECK.any? { |param| changes.include?(param) }
    end

    def build_canonical_email
      return unless @user.email_changed?

      Users::UpdateCanonicalEmailService.new(user: @user).execute
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
      if (metadata = @user.user_synced_attributes_metadata)
        read_only = metadata.read_only_attributes

        params.reject! { |key, _| read_only.include?(key.to_sym) }
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
      remove_followers_and_followee! if ::Feature.enabled?(:disable_follow_users, user)

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
