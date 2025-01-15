# frozen_string_literal: true

require 'securerandom'

module Gitlab
  module Utils
    class UsernameAndEmailGenerator
      include Gitlab::Utils::StrongMemoize

      def initialize(username_prefix:, email_domain: Gitlab.config.gitlab.host, random_segment: SecureRandom.hex(16))
        @username_prefix = username_prefix
        @email_domain = email_domain
        @random_segment = random_segment
      end

      def username
        uniquify.string(->(counter) { Kernel.sprintf(username_pattern, counter) }) do |suggested_username|
          suggested_email = email_for(suggested_username)

          ::Namespace.by_path(suggested_username) ||
            ::User.username_exists?(suggested_username) ||
            ::User.find_by_any_email(suggested_email) ||
            ::Email.find_by_email(suggested_email)
        end
      end
      strong_memoize_attr :username

      def email
        email_for(username)
      end
      strong_memoize_attr :email

      private

      attr_reader :random_segment, :username_prefix

      def username_pattern
        "#{username_prefix}_#{random_segment}%s"
      end

      def email_for(name)
        "#{name}@#{@email_domain}"
      end

      def uniquify
        Gitlab::Utils::Uniquify.new
      end
    end
  end
end
