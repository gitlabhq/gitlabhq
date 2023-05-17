# frozen_string_literal: true

module Gitlab
  module Cache
    # It replaces Rails.cache with metrics support
    class Client
      DEFAULT_BACKING_RESOURCE = :unknown

      # Build Cache client with the metadata support
      #
      # @param cache_identifier [String] defines the location of the cache definition
      #   Example: "ProtectedBranches::CacheService#fetch"
      # @param feature_category [Symbol] name of the feature category (from config/feature_categories.yml)
      # @param backing_resource [Symbol] most affected resource by cache generation (full list: VALID_BACKING_RESOURCES)
      # @return [Gitlab::Cache::Client]
      def self.build_with_metadata(
        cache_identifier:,
        feature_category:,
        backing_resource: DEFAULT_BACKING_RESOURCE
      )
        new(Metadata.new(
          cache_identifier: cache_identifier,
          feature_category: feature_category,
          backing_resource: backing_resource
        ))
      end

      def initialize(metadata, backend: Rails.cache)
        @metadata = metadata
        @metrics = Metrics.new(metadata)
        @backend = backend
      end

      def read(name)
        read_result = backend.read(name)

        if read_result.nil?
          metrics.increment_cache_miss
        else
          metrics.increment_cache_hit
        end

        read_result
      end

      def fetch(name, options = nil, &block)
        read_result = read(name)

        return read_result unless block || read_result

        backend.fetch(name, options) do
          metrics.observe_cache_generation(&block)
        end
      end

      delegate :write, :exist?, :delete, to: :backend

      attr_reader :metadata, :metrics

      private

      attr_reader :backend
    end
  end
end
