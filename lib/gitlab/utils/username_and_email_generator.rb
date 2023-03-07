# frozen_string_literal: true

require 'securerandom'

module Gitlab
  module Utils
    class UsernameAndEmailGenerator
      include Gitlab::Utils::StrongMemoize

      def initialize(username_prefix:, email_domain: Gitlab.config.gitlab.host)
        @username_prefix = username_prefix
        @email_domain = email_domain
      end

      def username
        uniquify.string(->(counter) { Kernel.sprintf(username_pattern, counter) }) do |suggested_username|
          ::Namespace.by_path(suggested_username) || ::User.find_by_any_email(email_for(suggested_username))
        end
      end
      strong_memoize_attr :username

      def email
        email_for(username)
      end
      strong_memoize_attr :email

      private

      def username_pattern
        "#{@username_prefix}_#{SecureRandom.hex(16)}%s"
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
