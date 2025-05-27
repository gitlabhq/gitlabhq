# frozen_string_literal: true

module ActiveContext
  module Databases
    module Opensearch
      class Executor
        include ActiveContext::Databases::Concerns::ElasticExecutor

        # These constants match the defaults on Elasticsearch
        # to ensure we have similar results on OpenSearch and Elasticsearch
        EF_CONSTRUCTION = 100
        M = 16

        def vector_field_mapping(field)
          {
            type: 'knn_vector',
            dimension: field.options[:dimensions],
            method: {
              name: 'hnsw',
              engine: 'lucene',
              space_type: 'cosinesimil',
              parameters: {
                ef_construction: EF_CONSTRUCTION,
                m: M
              }
            }
          }
        end

        def settings(fields)
          return super unless fields.any?(Field::Vector)

          super.merge({ index: { knn: true } })
        end
      end
    end
  end
end
