# OAuth extension for User model
#
# * Find GitLab user based on omniauth uid and provider
# * Create new user from omniauth data
#
module Gitlab
  module OAuth
    class User
      class << self
        attr_reader :auth

        def find(auth)
          @auth = auth
          find_by_uid_and_provider
        end

        def create(auth)
          @auth = auth
          password = Devise.friendly_token[0, 8].downcase
          opts = {
            extern_uid: uid,
            provider: provider,
            name: name,
            username: username,
            email: email,
            password: password,
            password_confirmation: password,
          }

          user = model.build_user(opts)
          user.skip_confirmation!

          # Services like twitter and github does not return email via oauth
          # In this case we generate temporary email and force user to fill it later
          if user.email.blank?
            user.generate_tmp_oauth_email
          elsif provider != "ldap"
            # Google oauth returns email but dont return nickname
            # So we use part of email as username for new user
            # For LDAP, username is already set to the user's
            # uid/userid/sAMAccountName.
            email_username = email.match(/^[^@]*/)[0]
            # Strip apostrophes since they are disallowed as part of username
            user.username = email_username.gsub("'", "")
          end

          begin
            user.save!
          rescue ActiveRecord::RecordInvalid => e
            log.info "(OAuth) Email #{e.record.errors[:email]}. Username #{e.record.errors[:username]}"
            return nil, e.record.errors
          end

          log.info "(OAuth) Creating user #{email} from login with extern_uid => #{uid}"

          if Gitlab.config.omniauth['block_auto_created_users'] && !ldap?
            user.block
          end

          user
        end

        private

        def find_by_uid_and_provider
          model.where(provider: provider, extern_uid: uid).last
        end

        def uid
          auth.info.uid || auth.uid
        end

        def email
          auth.info.email.downcase unless auth.info.email.nil?
        end

        def name
          if auth.info.name.nil?
            "#{auth.info.first_name} #{auth.info.last_name}".force_encoding('utf-8')
          else
            auth.info.name.to_s.force_encoding('utf-8')
          end
        end

        def username
          auth.info.nickname.to_s.force_encoding("utf-8")
        end

        def provider
          auth.provider
        end

        def log
          Gitlab::AppLogger
        end

        def model
          ::User
        end

        def raise_error(message)
          raise OmniAuth::Error, "(OAuth) " + message
        end

        def ldap?
          provider == 'ldap'
        end
      end
    end
  end
end
