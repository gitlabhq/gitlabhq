# OAuth extension for User model
#
# * Find GitLab user based on omniauth uid and provider
# * Create new user from omniauth data
#
module Gitlab
  module OAuth
    SignupDisabledError = Class.new(StandardError)

    class User
      prepend ::EE::Gitlab::OAuth::User

      attr_accessor :auth_hash, :gl_user

      def initialize(auth_hash)
        self.auth_hash = auth_hash
        update_email
      end

      def persisted?
        gl_user.try(:persisted?)
      end

      def new?
        !persisted?
      end

      def valid?
        gl_user.try(:valid?)
      end

      def save(provider = 'OAuth')
        unauthorized_to_create unless gl_user

        block_after_save = needs_blocking?

        Users::UpdateService.new(gl_user).execute!

        gl_user.block if block_after_save

        log.info "(#{provider}) saving user #{auth_hash.email} from login with extern_uid => #{auth_hash.uid}"
        gl_user
      rescue ActiveRecord::RecordInvalid => e
        log.info "(#{provider}) Error saving user #{auth_hash.uid} (#{auth_hash.email}): #{gl_user.errors.full_messages}"
        return self, e.record.errors
      end

      def gl_user
        @user ||= find_by_uid_and_provider

        if auto_link_ldap_user?
          @user ||= find_or_create_ldap_user
        end

        if signup_enabled?
          @user ||= build_new_user
        end

        if external_provider? && @user
          @user.external = true
        end

        @user
      end

      protected

      def find_or_create_ldap_user
        return unless ldap_person

        # If a corresponding person exists with same uid in a LDAP server,
        # check if the user already has a GitLab account.
        user = Gitlab::LDAP::User.find_by_uid_and_provider(ldap_person.dn, ldap_person.provider)
        if user
          # Case when a LDAP user already exists in Gitlab. Add the OAuth identity to existing account.
          log.info "LDAP account found for user #{user.username}. Building new #{auth_hash.provider} identity."
          user.identities.find_or_initialize_by(extern_uid: auth_hash.uid, provider: auth_hash.provider)
        else
          log.info "No existing LDAP account was found in GitLab. Checking for #{auth_hash.provider} account."
          user = find_by_uid_and_provider
          if user.nil?
            log.info "No user found using #{auth_hash.provider} provider. Creating a new one."
            user = build_new_user
          end
          log.info "Correct account has been found. Adding LDAP identity to user: #{user.username}."
          user.identities.new(provider: ldap_person.provider, extern_uid: ldap_person.dn)
        end

        user
      end

      def auto_link_ldap_user?
        Gitlab.config.omniauth.auto_link_ldap_user
      end

      def creating_linked_ldap_user?
        auto_link_ldap_user? && ldap_person
      end

      def ldap_person
        return @ldap_person if defined?(@ldap_person)

        # Look for a corresponding person with same uid in any of the configured LDAP providers
        Gitlab::LDAP::Config.providers.each do |provider|
          adapter = Gitlab::LDAP::Adapter.new(provider)
          @ldap_person = find_ldap_person(auth_hash, adapter)
          break if @ldap_person
        end
        @ldap_person
      end

      def find_ldap_person(auth_hash, adapter)
        by_uid = Gitlab::LDAP::Person.find_by_uid(auth_hash.uid, adapter)
        # The `uid` might actually be a DN. Try it next.
        by_uid || Gitlab::LDAP::Person.find_by_dn(auth_hash.uid, adapter)
      end

      def ldap_config
        Gitlab::LDAP::Config.new(ldap_person.provider) if ldap_person
      end

      def needs_blocking?
        new? && block_after_signup?
      end

      def signup_enabled?
        providers = Gitlab.config.omniauth.allow_single_sign_on
        if providers.is_a?(Array)
          providers.include?(auth_hash.provider)
        else
          providers
        end
      end

      def external_provider?
        Gitlab.config.omniauth.external_providers.include?(auth_hash.provider)
      end

      def block_after_signup?
        if creating_linked_ldap_user?
          ldap_config.block_auto_created_users
        else
          Gitlab.config.omniauth.block_auto_created_users
        end
      end

      def auth_hash=(auth_hash)
        @auth_hash = AuthHash.new(auth_hash)
      end

      def find_by_uid_and_provider
        identity = Identity.find_by(provider: auth_hash.provider, extern_uid: auth_hash.uid)
        identity && identity.user
      end

      def build_new_user
        user_params = user_attributes.merge(extern_uid: auth_hash.uid, provider: auth_hash.provider, skip_confirmation: true)
        Users::BuildService.new(nil, user_params).execute(skip_authorization: true)
      end

      def user_attributes
        # Give preference to LDAP for sensitive information when creating a linked account
        if creating_linked_ldap_user?
          username = ldap_person.username.presence
          email = ldap_person.email.first.presence
        end

        username ||= auth_hash.username
        email ||= auth_hash.email

        name = auth_hash.name
        name = ::Namespace.clean_path(username) if name.strip.empty?

        {
          name:                       name,
          username:                   ::Namespace.clean_path(username),
          email:                      email,
          password:                   auth_hash.password,
          password_confirmation:      auth_hash.password,
          password_automatically_set: true
        }
      end

      def sync_email_from_provider?
        auth_hash.provider.to_s == Gitlab.config.omniauth.sync_email_from_provider.to_s
      end

      def update_email
        if auth_hash.has_email? && sync_email_from_provider?
          if persisted?
            gl_user.skip_reconfirmation!
            gl_user.email = auth_hash.email
          end

          gl_user.external_email = true
          gl_user.email_provider = auth_hash.provider
        end
      end

      def log
        Gitlab::AppLogger
      end

      def unauthorized_to_create
        raise SignupDisabledError
      end
    end
  end
end
