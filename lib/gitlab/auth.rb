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
        @user.update_attributes(:extern_uid => uid, :provider => provider)
        @user
      else
        create_from_omniauth(auth, true)
      end
    end

    def create_from_omniauth(auth, ldap = false)
      creation_helper = UserCreationHelper.new(auth, ldap)
      log.info creation_helper.creation_message
      @user = User.create!(creation_helper.parameters, as: :admin)

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
        @user.update_attributes(:extern_uid => uid, :provider => provider)
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

    class UserCreationHelper
      def initialize(auth, ldap = false)
        @auth = auth
        @ldap = ldap
      end

      def parameters
        {
          extern_uid: uid,
          provider: provider,
          name: name,
          username: username,
          email: email,
          password: password,
          password_confirmation: password,
          projects_limit: Gitlab.config.gitlab.default_projects_limit 
        }
      end

      def uid
        (@auth.info.uid || @auth.uid).to_s.force_encoding("utf-8")
      end

      def provider
        @auth.info.provider
      end

      def name
        @auth.info.name.to_s.force_encoding("utf-8")
      end

      def username
        email.match(/^[^@]*/)[0]
      end

      def email
        auth.info.email.nil? ? email_error : auth.info.email.to_s.downcase
      end

      def password
        @password ||= Devise.friendly_token[0, 8].downcase
      end

      def creation_message
        "#{ldap_prefix}Creating user from #{provider} login"\
          " {uid => #{uid}, name => #{name}, email => #{email}}"
      end

      private

      def ldap_prefix
        ldap ? '(LDAP) ' : ''
      end

      def email_error
        raise OmniAuth::Error, "#{ldap_prefix}#{parameters.provider} does not"\
          " provide an email address" unless parameters.email
      end
    end

  end
end
