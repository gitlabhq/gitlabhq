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
        auth_hash.uid.to_s
      end

      def provider
        auth_hash.provider
      end

      def info
        auth_hash.info
      end

      def name
        (info.try(:name) || full_name).to_s.force_encoding('utf-8')
      end

      def full_name
        "#{info.first_name} #{info.last_name}"
      end

      def username
        (info.try(:nickname) || generate_username).to_s.force_encoding('utf-8')
      end

      def email
        (info.try(:email) || generate_temporarily_email).downcase
      end

      def password
        @password ||= Devise.friendly_token[0, 8].downcase
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
