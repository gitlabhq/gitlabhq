module Gitlab
  class Auth

    def find_or_new_for_omniauth(auth)
      provider = auth.provider
      uid = auth.info.uid || auth.uid
      name = auth.info.name.force_encoding("utf-8")
      email = auth.info.email.downcase unless auth.info.email.nil?

      if @user = User.find_by_provider_and_extern_uid(provider, uid)
        @user

      elsif email and @user = User.find_by_email(email)
        log.info "Updating legacy user #{email} with extern_uid => #{uid} from"\
            " #{provider} {uid => #{uid}, name => #{name}, email => #{email}}"
        @user.update_attributes(:extern_uid => uid, :provider => provider)
        @user

      elsif Gitlab.config.omniauth['allow_single_sign_on']

        raise OmniAuth::Error, "#{provider} does not provide an email"\
          " address" if auth.info.email.blank?

        log.info "Creating user from #{provider} login"\
          " {uid => #{uid}, name => #{name}, email => #{email}}"

        password = Devise.friendly_token[0, 8].downcase

        @user = User.new({
          extern_uid: uid,
          provider: provider,
          name: name,
          email: email,
          password: password,
          password_confirmation: password,
          projects_limit: Gitlab.config.default_projects_limit,
        }, as: :admin)

        if Gitlab.config.omniauth['block_auto_created_users']
          @user.blocked = true
        end

        @user.save!
        @user
      end
    end

    def log
      Gitlab::AppLogger
    end
  end
end
