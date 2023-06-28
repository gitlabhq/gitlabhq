# frozen_string_literal: true

module Gitlab
  module Cache
    # It replaces Rails.cache with metrics support
    class Client
      DEFAULT_BACKING_RESOURCE = :unknown
      DEFAULT_FEATURE_CATEGORY = :not_owned

      def initialize(metrics, backend: Rails.cache)
        @metrics = metrics
        @backend = backend
      end

      def read(name, options = nil, labels = {})
        read_result = backend.read(name, options)

        if read_result.nil?
          metrics.increment_cache_miss(labels)
        else
          metrics.increment_cache_hit(labels)
        end

        read_result
      end

      def fetch(name, options = nil, labels = {}, &block)
        read_result = read(name, options, labels)

        return read_result unless block || read_result

        backend.fetch(name, options) do
          metrics.observe_cache_generation(labels, &block)
        end
      end

      delegate :write, :exist?, :delete, to: :backend

      private

      attr_reader :metrics, :backend
    end
  end
end
