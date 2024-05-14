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
        slug = Gitlab::Slug::Path.new(external_username).generate

        # remove leading - , _ , or . characters not removed by Namespace.clean_path
        slug = slug.sub(/\A[_.-]+/, '')

        # remove trailing - , _ or . characters not removed by Namespace.clean_path
        # hard to write a regex to match end-of-string without ReDoS, so just use plain Ruby
        slug = slug[0...-1] while slug.end_with?('.', '-', '_')

        # remove consecutive - , _ , or . characters
        slug = slug.gsub(/([_.-])[_.-]+/, '\1')

        slug = unique_by_namespace(slug)

        validated_path(slug)
      end

      # decomposed from Namespace.clean_path
      def unique_by_namespace(slug)
        path = Namespaces::RandomizedSuffixPath.new(slug).to_s
        Gitlab::Utils::Uniquify.new.string(path) do |s|
          Namespace.all.find_by_path_or_name(s)
        end
      end

      def validated_path(path)
        Gitlab::Utils::Uniquify.new.string(path) do |s|
          !NamespacePathValidator.valid_path?(s)
        end
      end
    end
  end
end
