# frozen_string_literal: true

module Gitlab
  module Cache
    # Value object for cache metadata
    class Metadata
      VALID_BACKING_RESOURCES = [:cpu, :database, :gitaly, :memory, :unknown].freeze
      DEFAULT_BACKING_RESOURCE = :unknown

      def initialize(
        cache_identifier:,
        feature_category:,
        caller_id: Gitlab::ApplicationContext.current_context_attribute(:caller_id),
        backing_resource: DEFAULT_BACKING_RESOURCE
      )
        @cache_identifier = cache_identifier
        @feature_category = Gitlab::FeatureCategories.default.get!(feature_category)
        @caller_id = caller_id
        @backing_resource = fetch_backing_resource!(backing_resource)
      end

      attr_reader :caller_id, :cache_identifier, :feature_category, :backing_resource

      private

      def fetch_backing_resource!(resource)
        return resource if VALID_BACKING_RESOURCES.include?(resource)

        raise "Unknown backing resource: #{resource}" if Gitlab.dev_or_test_env?

        DEFAULT_BACKING_RESOURCE
      end
    end
  end
end
