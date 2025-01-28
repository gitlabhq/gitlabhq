# frozen_string_literal: true

module ActiveContext
  module Databases
    module Opensearch
      class Adapter
        include ActiveContext::Databases::Concerns::Adapter

        def client_klass
          ActiveContext::Databases::Opensearch::Client
        end

        def indexer_klass
          ActiveContext::Databases::Opensearch::Indexer
        end
      end
    end
  end
end
