module Users
  class BuildService < BaseService
    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params.dup
    end

    def execute(skip_authorization: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || can_create_user?

      user_params = build_user_params(skip_authorization: skip_authorization)
      user = User.new(user_params)

      if current_user&.admin?
        @reset_token = user.generate_reset_token if params[:reset_password]

        if user_params[:force_random_password]
          random_password = Devise.friendly_token.first(Devise.password_length.min)
          user.password = user.password_confirmation = random_password
        end
      end

      identity_attrs = params.slice(:extern_uid, :provider)

      if identity_attrs.any?
        user.identities.build(identity_attrs)
      end

      user
    end

    private

    def can_create_user?
      (current_user.nil? && Gitlab::CurrentSettings.allow_signup?) || current_user&.admin?
    end

    # Allowed params for creating a user (admins only)
    def admin_create_params
      [
        :access_level,
        :admin,
        :avatar,
        :bio,
        :can_create_group,
        :color_scheme_id,
        :email,
        :external,
        :force_random_password,
        :hide_no_password,
        :hide_no_ssh_key,
        :key_id,
        :linkedin,
        :name,
        :password,
        :password_automatically_set,
        :password_expires_at,
        :projects_limit,
        :remember_me,
        :skip_confirmation,
        :skype,
        :theme_id,
        :twitter,
        :username,
        :website_url
      ]
    end

    # Allowed params for user signup
    def signup_params
      [
        :email,
        :email_confirmation,
        :password_automatically_set,
        :name,
        :password,
        :username
      ]
    end

    def build_user_params(skip_authorization:)
      if current_user&.admin?
        user_params = params.slice(*admin_create_params)
        user_params[:created_by_id] = current_user&.id

        if params[:reset_password]
          user_params.merge!(force_random_password: true, password_expires_at: nil)
        end
      else
        allowed_signup_params = signup_params
        allowed_signup_params << :skip_confirmation if skip_authorization

        user_params = params.slice(*allowed_signup_params)
        if user_params[:skip_confirmation].nil?
          user_params[:skip_confirmation] = skip_user_confirmation_email_from_setting
        end
      end

      user_params
    end

    def skip_user_confirmation_email_from_setting
      !Gitlab::CurrentSettings.send_user_confirmation_email
    end
  end
end
