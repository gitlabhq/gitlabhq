# Class to parse and transform the info provided by omniauth
#
module Gitlab
  module Auth
    module OAuth
      class AuthHash
        attr_reader :auth_hash
        def initialize(auth_hash)
          @auth_hash = auth_hash
        end

        def uid
          @uid ||= Gitlab::Utils.force_utf8(auth_hash.uid.to_s)
        end

        def provider
          @provider ||= auth_hash.provider.to_s
        end

        def name
          @name ||= get_info(:name) || "#{get_info(:first_name)} #{get_info(:last_name)}"
        end

        def username
          @username ||= username_and_email[:username].to_s
        end

        def email
          @email ||= username_and_email[:email].to_s
        end

        def password
          @password ||= Gitlab::Utils.force_utf8(Devise.friendly_token[0, 8].downcase)
        end

        def location
          location = get_info(:address)
          if location.is_a?(Hash)
            [location.locality.presence, location.country.presence].compact.join(', ')
          else
            location
          end
        end

        def has_attribute?(attribute)
          if attribute == :location
            get_info(:address).present?
          else
            get_info(attribute).present?
          end
        end

        private

        def info
          auth_hash.info
        end

        def get_info(key)
          value = info[key]
          Gitlab::Utils.force_utf8(value) if value
          value
        end

        def username_and_email
          @username_and_email ||= begin
            username  = get_info(:username).presence || get_info(:nickname).presence
            email     = get_info(:email).presence

            username ||= generate_username(email)             if email
            email    ||= generate_temporarily_email(username) if username

            {
              username: username,
              email:    email
            }
          end
        end

        # Get the first part of the email address (before @)
        # In addtion in removes illegal characters
        def generate_username(email)
          email.match(/^[^@]*/)[0].mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/, '').to_s
        end

        def generate_temporarily_email(username)
          "temp-email-for-oauth-#{username}@gitlab.localhost"
        end
      end
    end
  end
end
