# frozen_string_literal: true

module Search
  module Worker
    extend ActiveSupport::Concern

    included do
      feature_category :global_search
      concurrency_limit -> { ::Search.default_concurrency_limit }
    end

    private

    def logger
      ::Gitlab::Elasticsearch::Logger.build
    end
  end
end
