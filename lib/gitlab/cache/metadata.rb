# frozen_string_literal: true

module Gitlab
  module Cache
    # Value object for cache metadata
    class Metadata
      VALID_BACKING_RESOURCES = [:cpu, :database, :gitaly, :memory, :unknown].freeze

      # @param cache_identifier [String] defines the location of the cache definition
      #   Example: "ProtectedBranches::CacheService#fetch"
      # @param feature_category [Symbol] name of the feature category (from config/feature_categories.yml)
      # @param backing_resource [Symbol] most affected resource by cache generation (full list: VALID_BACKING_RESOURCES)
      # @return [Gitlab::Cache::Metadata]
      def initialize(
        cache_identifier: nil,
        feature_category: Client::DEFAULT_FEATURE_CATEGORY,
        backing_resource: Client::DEFAULT_BACKING_RESOURCE
      )
        @cache_identifier = cache_identifier
        @feature_category = fetch_feature_category!(feature_category)
        @backing_resource = fetch_backing_resource!(backing_resource)
      end

      attr_reader :cache_identifier, :feature_category, :backing_resource

      private

      def fetch_feature_category!(feature_category)
        return feature_category if feature_category == Client::DEFAULT_FEATURE_CATEGORY

        Gitlab::FeatureCategories.default.get!(feature_category)
      end

      def fetch_backing_resource!(resource)
        return resource if VALID_BACKING_RESOURCES.include?(resource)

        raise "Unknown backing resource: #{resource}" if Gitlab.dev_or_test_env?

        Client::DEFAULT_BACKING_RESOURCE
      end
    end
  end
end
