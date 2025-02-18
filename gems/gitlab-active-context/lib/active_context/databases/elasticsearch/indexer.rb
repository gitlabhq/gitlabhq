# frozen_string_literal: true

module ActiveContext
  module Databases
    module Elasticsearch
      class Indexer
        include ActiveContext::Databases::Concerns::ElasticIndexer
      end
    end
  end
end
