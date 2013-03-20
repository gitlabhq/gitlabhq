module Gitlab
  class Auth
    class Error < StandardError; end

    def find_for_ldap_auth(auth, signed_in_resource = nil)
      uid = auth.info.uid
      provider = auth.provider
      email = auth.info.email.downcase unless auth.info.email.nil?
      raise OmniAuth::Error, "LDAP accounts must provide an uid and email address" if uid.nil? or email.nil?

      if @user = User.find_by_extern_uid_and_provider(uid, provider)
        @user
      elsif @user = User.find_by_email(email)
        log.info "Updating legacy LDAP user #{email} with extern_uid => #{uid}"
        @user.update_attributes(:extern_uid => uid, :provider => provider)
        @user
      else
        create_from_omniauth(auth, true)
      end
    end

    def find_or_new_for_omniauth(auth)
      provider, uid = auth.provider, auth.uid.to_s.force_encoding("utf-8")
      email = auth.info.email.to_s.downcase unless auth.info.email.nil?

      raise Error, "Omniauth provider must provide uid" if uid.nil?

      if @user = User.find_by_provider_and_extern_uid(provider, uid)
        @user
      elsif @user = User.find_by_email(email)
        log.info "Updating user {email: #{email}, provider: #{@user.provider}, extern_uid: #{@user.extern_uid}} with {provider: #{provider}, extern_uid: #{uid}}"
        @user.update_attributes(:extern_uid => uid, :provider => provider)
        @user
      else
        allow_sso = Devise.omniauth_configs[provider.to_sym].options['allow_single_sign_on']
        allow_sso = Gitlab.config.omniauth['allow_single_sign_on'] if allow_sso.nil?
        if allow_sso
          @user = create_from_omniauth(auth)
        end
      end
    end

    private

    def log
      Gitlab::AppLogger
    end

    def create_from_omniauth(auth, ldap = false)
      provider, uid = auth.provider, auth.uid.to_s.force_encoding("utf-8")
      name = auth.info.name.to_s.force_encoding("utf-8")
      email = auth.info.email.to_s.downcase unless auth.info.email.nil?

      raise Error, "#{provider} does not provide an email address" if email.nil? || email.blank?

      log.info "Creating user from #{provider} login {uid => #{uid}, name => #{name}, email => #{email}}"
      password = Devise.friendly_token[0, 8].downcase
      @user = User.new({
        extern_uid: uid,
        provider: provider,
        name: name,
        username: email.match(/^[^@]*/)[0],
        email: email,
        password: password,
        password_confirmation: password,
        projects_limit: Gitlab.config.gitlab.default_projects_limit,
      }, as: :admin)
      @user.save!

      block = Devise.omniauth_configs[provider.to_sym].options['block_auto_created_users']
      block = Gitlab.config.omniauth['block_auto_created_users'] if block.nil?
      if block
        @user.block
      end

      @user
    end
  end
end
