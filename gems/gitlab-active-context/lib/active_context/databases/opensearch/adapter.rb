# frozen_string_literal: true

module ActiveContext
  module Databases
    module Opensearch
      class Adapter
        include ActiveContext::Databases::Concerns::Adapter

        def name
          'opensearch'
        end

        def client_klass
          ActiveContext::Databases::Opensearch::Client
        end

        def indexer_klass
          ActiveContext::Databases::Opensearch::Indexer
        end

        def executor_klass
          ActiveContext::Databases::Opensearch::Executor
        end
      end
    end
  end
end
