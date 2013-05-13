module Gitlab
  class Auth
    def find_for_ldap_auth(auth, signed_in_resource = nil)
      uid = auth.info.uid
      provider = auth.provider
      email = auth.info.email.downcase unless auth.info.email.nil?
      raise OmniAuth::Error, "LDAP accounts must provide an uid and email address" if uid.nil? or email.nil?

      if @user = User.find_by_extern_uid_and_provider(uid, provider)
        @user
      elsif @user = User.find_by_email(email)
        log.info "Updating legacy LDAP user #{email} with extern_uid => #{uid}"
        @user.update_attributes(extern_uid: uid, provider: provider)
        @user
      else
        create_from_omniauth(auth, true)
      end
    end

    def create_from_omniauth(auth, ldap = false)
      provider = auth.provider
      uid = auth.info.uid || auth.uid
      uid = uid.to_s.force_encoding("utf-8")
      name = auth.info.name.to_s.force_encoding("utf-8")
      if ldap && Gitlab.config.ldap['email']
        # auth.extra.raw_info is the raw ldap data which consists of
        # lists of values
        # When ldap mappings are explicitly given, don't do a fallback
        email = auth.extra.raw_info[Gitlab.config.ldap.username][0].to_s.downcase
        log.info "(LDAP) Using '#{Gitlab.config.ldap.email}' to get email => #{email} from LDAP for #{uid}"
      else
        email = auth.info.email.to_s.downcase unless auth.info.email.nil?
      end

      if ldap && Gitlab.config.ldap['username']
        username = auth.extra.raw_info[Gitlab.config.ldap.username][0].to_s.force_encoding("utf-8")
        log.info "(#{provider}) Using '#{Gitlab.config.ldap.username}' to get username => #{username} for #{uid}"
      else
        username = email.match(/^[^@]*/)[0]
      end
      
      raise OmniAuth::Error, "#{provider} does not provide an email"\
        " address" if auth.info.email.blank?

      log.info "Creating user from #{provider} login"\
        " {uid => #{uid}, name => #{name}, email => #{email}, username => #{username}}"
      password = Devise.friendly_token[0, 8].downcase
      @user = User.new({
        extern_uid: uid,
        provider: provider,
        name: name,
        username: username,
        email: email,
        password: password,
        password_confirmation: password,
        projects_limit: Gitlab.config.gitlab.default_projects_limit,
      }, as: :admin)
      @user.save!

      if Gitlab.config.omniauth['block_auto_created_users'] && !ldap
        @user.block
      end

      @user
    end

    def find_or_new_for_omniauth(auth)
      provider, uid = auth.provider, auth.uid
      email = auth.info.email.downcase unless auth.info.email.nil?

      if @user = User.find_by_provider_and_extern_uid(provider, uid)
        @user
      elsif @user = User.find_by_email(email)
        @user.update_attributes(extern_uid: uid, provider: provider)
        @user
      else
        if Gitlab.config.omniauth['allow_single_sign_on']
          @user = create_from_omniauth(auth)
          @user
        end
      end
    end

    def log
      Gitlab::AppLogger
    end
  end
end
