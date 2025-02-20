# frozen_string_literal: true

module ActiveContext
  module Databases
    module Elasticsearch
      class Executor
        include ActiveContext::Databases::Concerns::ElasticExecutor

        def vector_field_mapping(field)
          {
            type: 'dense_vector',
            dims: field.options[:dimensions],
            index: true,
            similarity: 'cosine'
          }
        end
      end
    end
  end
end
