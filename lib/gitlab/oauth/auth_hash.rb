# Class to parse and transform the info provided by omniauth
#
module Gitlab
  module OAuth
    class AuthHash
      attr_reader :auth_hash
      def initialize(auth_hash)
        @auth_hash = auth_hash
      end

      def uid
        Gitlab::Utils.encode_utf8(auth_hash.uid.to_s)
      end

      def provider
        Gitlab::Utils.encode_utf8(auth_hash.provider.to_s)
      end

      def info
        auth_hash.info
      end

      def name
        Gitlab::Utils.encode_utf8((info.try(:name) || full_name).to_s)
      end

      def full_name
        Gitlab::Utils.encode_utf8("#{info.first_name} #{info.last_name}")
      end

      def username
        Gitlab::Utils.encode_utf8((info.try(:nickname) || generate_username).to_s)
      end

      def email
        Gitlab::Utils.encode_utf8((info.try(:email) || generate_temporarily_email).downcase)
      end

      def password
        @password ||= Gitlab::Utils.encode_utf8(Devise.friendly_token[0, 8].downcase)
      end

      # Get the first part of the email address (before @)
      # In addtion in removes illegal characters
      def generate_username
        email.match(/^[^@]*/)[0].parameterize
      end

      def generate_temporarily_email
        "temp-email-for-oauth-#{username}@gitlab.localhost"
      end
    end
  end
end
