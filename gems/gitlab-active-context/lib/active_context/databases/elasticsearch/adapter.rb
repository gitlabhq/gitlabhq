# frozen_string_literal: true

module ActiveContext
  module Databases
    module Elasticsearch
      class Adapter
        include ActiveContext::Databases::Concerns::Adapter

        def name
          'elasticsearch'
        end

        def client_klass
          ActiveContext::Databases::Elasticsearch::Client
        end

        def indexer_klass
          ActiveContext::Databases::Elasticsearch::Indexer
        end

        def executor_klass
          ActiveContext::Databases::Elasticsearch::Executor
        end

        def indexer_connection_options
          { url: normalize_urls(options[:url]) }
        end
      end
    end
  end
end
