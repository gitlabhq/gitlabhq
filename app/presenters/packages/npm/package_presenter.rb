# frozen_string_literal: true

module Packages
  module Npm
    class PackagePresenter
      def initialize(metadata)
        @metadata = metadata
      end

      def name
        metadata[:name]
      end

      def versions
        metadata[:versions]
      end

      def dist_tags
        metadata[:dist_tags]
      end

      private

      attr_reader :metadata
    end
  end
end
