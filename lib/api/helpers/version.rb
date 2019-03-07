# frozen_string_literal: true

module API
  module Helpers
    class Version
      include Helpers::RelatedResourcesHelpers

      def initialize(version)
        @version = version.to_s

        unless API.versions.include?(version)
          raise ArgumentError, 'Unknown API version!'
        end
      end

      def root_path
        File.join('/', API.prefix.to_s, @version)
      end

      def root_url
        @root_url ||= expose_url(root_path)
      end

      def to_s
        @version
      end
    end
  end
end
