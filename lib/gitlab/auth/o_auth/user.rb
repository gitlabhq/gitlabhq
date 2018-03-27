# OAuth extension for User model
#
# * Find GitLab user based on omniauth uid and provider
# * Create new user from omniauth data
#
module Gitlab
  module Auth
    module OAuth
      class User
        SignupDisabledError = Class.new(StandardError)
        SigninDisabledForProviderError = Class.new(StandardError)

        attr_accessor :auth_hash, :gl_user

        def initialize(auth_hash)
          self.auth_hash = auth_hash
          update_profile
          add_or_update_user_identities
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
          raise SigninDisabledForProviderError if oauth_provider_disabled?
          raise SignupDisabledError unless gl_user

          block_after_save = needs_blocking?

          Users::UpdateService.new(gl_user, user: gl_user).execute!

          gl_user.block if block_after_save

          log.info "(#{provider}) saving user #{auth_hash.email} from login with extern_uid => #{auth_hash.uid}"
          gl_user
        rescue ActiveRecord::RecordInvalid => e
          log.info "(#{provider}) Error saving user #{auth_hash.uid} (#{auth_hash.email}): #{gl_user.errors.full_messages}"
          return self, e.record.errors
        end

        def gl_user
          return @gl_user if defined?(@gl_user)

          @gl_user = find_user
        end

        def find_user
          user = find_by_uid_and_provider

          user ||= find_or_build_ldap_user if auto_link_ldap_user?
          user ||= build_new_user if signup_enabled?

          user.external = true if external_provider? && user&.new_record?

          user
        end

        protected

        def add_or_update_user_identities
          return unless gl_user

          # find_or_initialize_by doesn't update `gl_user.identities`, and isn't autosaved.
          identity = gl_user.identities.find { |identity| identity.provider == auth_hash.provider }

          identity ||= gl_user.identities.build(provider: auth_hash.provider)
          identity.extern_uid = auth_hash.uid

          if auto_link_ldap_user? && !gl_user.ldap_user? && ldap_person
            log.info "Correct LDAP account has been found. identity to user: #{gl_user.username}."
            gl_user.identities.build(provider: ldap_person.provider, extern_uid: ldap_person.dn)
          end
        end

        def find_or_build_ldap_user
          return unless ldap_person

          user = Gitlab::Auth::LDAP::User.find_by_uid_and_provider(ldap_person.dn, ldap_person.provider)
          if user
            log.info "LDAP account found for user #{user.username}. Building new #{auth_hash.provider} identity."
            return user
          end

          log.info "No user found using #{auth_hash.provider} provider. Creating a new one."
          build_new_user
        end

        def find_by_email
          return unless auth_hash.has_attribute?(:email)

          ::User.find_by(email: auth_hash.email.downcase)
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
          Gitlab::Auth::LDAP::Config.providers.each do |provider|
            adapter = Gitlab::Auth::LDAP::Adapter.new(provider)
            @ldap_person = find_ldap_person(auth_hash, adapter)
            break if @ldap_person
          end
          @ldap_person
        end

        def find_ldap_person(auth_hash, adapter)
          Gitlab::Auth::LDAP::Person.find_by_uid(auth_hash.uid, adapter) ||
            Gitlab::Auth::LDAP::Person.find_by_email(auth_hash.uid, adapter) ||
            Gitlab::Auth::LDAP::Person.find_by_dn(auth_hash.uid, adapter)
        end

        def ldap_config
          Gitlab::Auth::LDAP::Config.new(ldap_person.provider) if ldap_person
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
          identity = Identity.with_extern_uid(auth_hash.provider, auth_hash.uid).take
          identity&.user
        end

        def build_new_user
          user_params = user_attributes.merge(skip_confirmation: true)
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

          valid_username = ::Namespace.clean_path(username)

          uniquify = Uniquify.new
          valid_username = uniquify.string(valid_username) { |s| !NamespacePathValidator.valid_path?(s) }

          name = auth_hash.name
          name = valid_username if name.strip.empty?

          {
            name:                       name,
            username:                   valid_username,
            email:                      email,
            password:                   auth_hash.password,
            password_confirmation:      auth_hash.password,
            password_automatically_set: true
          }
        end

        def sync_profile_from_provider?
          Gitlab::Auth::OAuth::Provider.sync_profile_from_provider?(auth_hash.provider)
        end

        def update_profile
          clear_user_synced_attributes_metadata

          return unless sync_profile_from_provider? || creating_linked_ldap_user?

          metadata = gl_user.build_user_synced_attributes_metadata

          if sync_profile_from_provider?
            UserSyncedAttributesMetadata::SYNCABLE_ATTRIBUTES.each do |key|
              if auth_hash.has_attribute?(key) && gl_user.sync_attribute?(key)
                gl_user[key] = auth_hash.public_send(key) # rubocop:disable GitlabSecurity/PublicSend
                metadata.set_attribute_synced(key, true)
              else
                metadata.set_attribute_synced(key, false)
              end
            end

            metadata.provider = auth_hash.provider
          end

          if creating_linked_ldap_user? && gl_user.email == ldap_person.email.first
            metadata.set_attribute_synced(:email, true)
            metadata.provider = ldap_person.provider
          end
        end

        def clear_user_synced_attributes_metadata
          gl_user&.user_synced_attributes_metadata&.destroy
        end

        def log
          Gitlab::AppLogger
        end

        def oauth_provider_disabled?
          Gitlab::CurrentSettings.current_application_settings
                                .disabled_oauth_sign_in_sources
                                .include?(auth_hash.provider)
        end
      end
    end
  end
end
