# frozen_string_literal: true

# Class to parse and transform the info provided by omniauth
#
module Gitlab
  module Auth
    module OAuth
      class AuthHash
        attr_reader :auth_hash
        attr_accessor :errors

        def initialize(auth_hash)
          @auth_hash = auth_hash
          @errors = {}
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
          @password ||= Gitlab::Utils.force_utf8(::User.random_password)
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
          auth_hash['info']
        end

        def coerce_utf8(value)
          value.is_a?(String) ? Gitlab::Utils.force_utf8(value) : value
        end

        def get_info(key)
          coerce_utf8(info[key])
        end

        def provider_config
          Gitlab::Auth::OAuth::Provider.config_for(provider) || {}
        end

        def provider_args
          @provider_args ||= provider_config['args'].presence || {}
        end

        def get_from_auth_hash_or_info(key)
          if auth_hash.key?(key)
            coerce_utf8(auth_hash[key])
          elsif auth_hash.key?(:extra) && auth_hash.extra.key?(:raw_info) && !auth_hash.extra.raw_info[key].blank?
            coerce_utf8(auth_hash.extra.raw_info[key])
          else
            get_info(key)
          end
        end

        # Allow for configuring a custom username claim per provider from
        # the auth hash or use the canonical username or nickname fields
        def gitlab_username_claim
          provider_args['gitlab_username_claim']&.to_sym
        end

        def username_claims
          [gitlab_username_claim, :username, :nickname].compact
        end

        def get_username
          username_claims.map { |claim| get_from_auth_hash_or_info(claim) }
            .find { |name| name.presence }
            &.split("@")
            &.first
        end

        def username_and_email
          @username_and_email ||= begin
            username  = get_username
            email     = get_info(:email).presence

            username ||= generate_username(email)             if email
            email    ||= generate_temporarily_email(username) if username

            {
              username: username,
              email: email
            }
          end
        end

        # Get the first part of the email address (before @)
        # In addition in removes illegal characters
        # Perform length validation twice:
        # - Before normalization to prevent normalizing excessively long strings
        # - After normalization to ensure certain normalized multibyte characters don't exceed length.
        def generate_username(email)
          return unless valid_email_username_length?(email)

          username = mb_chars_unicode_normalize(email.match(/^[^@]*/)[0])
          username if valid_email_username_length?(username)
        end

        def generate_temporarily_email(username)
          "temp-email-for-oauth-#{username}@gitlab.localhost"
        end

        # RFC 3606 and RFC 2821 restrict total email length to
        # 254 characters. Do not allow longer emails to be passed in
        # because unicode normalization can be intensive.
        def valid_email_username_length?(email_or_username)
          return true if email_or_username.length <= 254

          errors[:identity_provider_email] = _("must be 254 characters or less.")
          false
        end

        def mb_chars_unicode_normalize(string)
          string.mb_chars.unicode_normalize(:nfkd).gsub(/[^\x00-\x7F]/, '').to_s
        end
      end
    end
  end
end

Gitlab::Auth::OAuth::AuthHash.prepend_mod_with('Gitlab::Auth::OAuth::AuthHash')
