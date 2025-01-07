# frozen_string_literal: true

module Users
  class BuildService < BaseService
    ALLOWED_USER_TYPES = %i[project_bot security_policy_bot].freeze

    delegate :user_default_internal_regex_enabled?,
      :user_default_internal_regex_instance,
      to: :'Gitlab::CurrentSettings.current_application_settings'

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params.dup
      @organization_params = params.slice(*organization_attributes).compact
      @identity_params = params.slice(*identity_attributes)
    end

    def execute
      build_user
      build_identity

      user
    end

    private

    attr_reader :identity_params, :user_params, :user, :organization_params

    def organization_attributes
      admin? ? admin_organization_attributes : signup_organization_attributes
    end

    def identity_attributes
      [:extern_uid, :provider]
    end

    def build_user
      if admin?
        admin_build_user
      else
        standard_build_user
      end

      assign_organization
      assign_personal_namespace
    end

    def admin?
      return false unless current_user

      current_user.admin?
    end

    def admin_build_user
      build_user_params_for_admin
      init_user
      password_reset
    end

    def standard_build_user
      # current_user non admin or nil
      validate_access!
      build_user_params_for_non_admin
      init_user
    end

    def build_user_params_for_admin
      @user_params = params.slice(*admin_create_params)
      @user_params.merge!(force_random_password: true, password_expires_at: nil) if params[:reset_password]
    end

    def init_user
      assign_common_user_params

      # We'll declaratively initialize the user_detail here due to possibility of assignment to user_detail
      # in a delegation or otherwise in the assignment of attributes.
      # This will allow our after_initialize call at the model layer to not wipe those values out and will
      # also allow use to remove the model layer `user_detail` override eventually.
      # Any future calls outside of this class on User.new can still wipe out set user_detail values, but
      # once we remove the model layer override, it will be caught during test and that area, if not using
      # this class will have to build_user_detail as well.
      @user = User.new.tap do |base_user|
        base_user.build_user_detail
        base_user.assign_attributes(user_params)
      end
    end

    def organization_access_level
      return organization_params[:organization_access_level] if organization_params.has_key?(:organization_access_level)

      Organizations::OrganizationUser.default_organization_access_level(user_is_admin: @user.admin?)
    end

    def assign_organization
      # Allow invalid parameters for the validation errors to bubble up to the User.
      return if organization_params.blank?

      @user.organization_users << Organizations::OrganizationUser.new(
        organization_id: organization_params[:organization_id],
        access_level: organization_access_level
      )
    end

    def assign_personal_namespace
      organization = Organizations::Organization.find_by_id(organization_params[:organization_id])
      user.assign_personal_namespace(organization)
    end

    def assign_common_user_params
      @user_params[:created_by_id] = current_user&.id
      @user_params[:external] = user_external? if set_external_param?

      @user_params.delete(:user_type) unless allowed_user_type?
    end

    def set_external_param?
      user_default_internal_regex_enabled? && !user_params.key?(:external)
    end

    def user_external?
      user_default_internal_regex_instance.match(params[:email]).nil?
    end

    def allowed_user_type?
      ALLOWED_USER_TYPES.include?(user_params[:user_type]&.to_sym)
    end

    def password_reset
      @reset_token = user.generate_reset_token if params[:reset_password]

      if user_params[:force_random_password]
        random_password = User.random_password
        @user.password = user.password_confirmation = random_password
      end
    end

    def validate_access!
      return if can_create_user?

      raise Gitlab::Access::AccessDeniedError
    end

    def can_create_user?
      current_user.nil? && Gitlab::CurrentSettings.allow_signup?
    end

    def build_user_params_for_non_admin
      @user_params = params.slice(*signup_params)
      # if skip_confirmation is set to `true`, devise will set confirmed_at
      # see: https://github.com/heartcombo/devise/blob/8593801130f2df94a50863b5db535c272b00efe1/lib/devise/models/confirmable.rb#L156
      @user_params[:skip_confirmation] = skip_user_confirmation_email_from_setting if assign_skip_confirmation_from_settings?
      @user_params[:name] = fallback_name if use_fallback_name?
    end

    def assign_skip_confirmation_from_settings?
      user_params[:skip_confirmation].nil?
    end

    def skip_user_confirmation_email_from_setting
      Gitlab::CurrentSettings.email_confirmation_setting_off?
    end

    def use_fallback_name?
      user_params[:name].blank? && fallback_name.present?
    end

    def fallback_name
      "#{user_params[:first_name]} #{user_params[:last_name]}"
    end

    def build_identity
      return if identity_params.empty?

      user.identities.build(identity_params)
    end

    # Allowed params for creating a user (admins only)
    def admin_create_params
      [
        :access_level,
        :admin,
        :avatar,
        :bio,
        :bot_namespace,
        :can_create_group,
        :color_mode_id,
        :color_scheme_id,
        :discord,
        :email,
        :external,
        :force_random_password,
        :hide_no_password,
        :hide_no_ssh_key,
        :linkedin,
        :location,
        :name,
        :note,
        :organization,
        :password,
        :password_automatically_set,
        :password_expires_at,
        :private_profile,
        :projects_limit,
        :public_email,
        :remember_me,
        :skip_confirmation,
        :skype,
        :theme_id,
        :twitter,
        :user_type,
        :username,
        :view_diffs_file_by_file,
        :website_url
      ]
    end

    def admin_organization_attributes
      [:organization_id, :organization_access_level]
    end

    # Allowed params for user signup
    def signup_params
      [
        :email,
        :name,
        :password,
        :password_automatically_set,
        :preferred_language,
        :username,
        :user_type,
        :first_name,
        :last_name
      ]
    end

    def signup_organization_attributes
      [:organization_id]
    end
  end
end

Users::BuildService.prepend_mod_with('Users::BuildService')
