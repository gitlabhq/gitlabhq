# frozen_string_literal: true

module Gitlab
  module Auth
    class ExternalUsernameSanitizer
      attr_reader :external_username

      def initialize(external_username)
        @external_username = external_username
      end

      def sanitize
        # remove most characters illegal in usernames / slugs
        valid_username = ::Namespace.clean_path(external_username)
        # remove leading - , _ , or . characters not removed by Namespace.clean_path
        valid_username = valid_username.sub(/\A[_.-]+/, '')
        # remove trailing - , _ or . characters not removed by Namespace.clean_path
        valid_username = valid_username.sub(/[_.-]+\z/, '')
        # remove consecutive - , _ , or . characters
        valid_username = valid_username.gsub(/([_.-])[_.-]+/, '\1')
        Gitlab::Utils::Uniquify.new.string(valid_username) do |s|
          !NamespacePathValidator.valid_path?(s)
        end
      end
    end
  end
end
