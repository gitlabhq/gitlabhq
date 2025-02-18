# frozen_string_literal: true

module ActiveContext
  module Databases
    module Opensearch
      class Indexer
        include ActiveContext::Databases::Concerns::ElasticIndexer
      end
    end
  end
end
