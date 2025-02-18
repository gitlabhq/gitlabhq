# frozen_string_literal: true

module ActiveContext
  module Databases
    module Elasticsearch
      class Adapter
        include ActiveContext::Databases::Concerns::Adapter

        def client_klass
          ActiveContext::Databases::Elasticsearch::Client
        end

        def indexer_klass
          ActiveContext::Databases::Elasticsearch::Indexer
        end

        def executor_klass
          ActiveContext::Databases::Elasticsearch::Executor
        end
      end
    end
  end
end
