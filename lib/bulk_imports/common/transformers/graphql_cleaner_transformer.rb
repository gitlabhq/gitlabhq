# frozen_string_literal: true

# Cleanup GraphQL original response hash from unnecessary nesting
# 1. Remove ['data']['group'] or ['data']['project'] hash nesting
# 2. Remove ['edges'] & ['nodes'] array wrappings
# 3. Remove ['node'] hash wrapping
#
# @example
#   data = {"data"=>{"group"=> {
#     "name"=>"test",
#     "fullName"=>"test",
#     "description"=>"test",
#     "labels"=>{"edges"=>[{"node"=>{"title"=>"label1"}}, {"node"=>{"title"=>"label2"}}, {"node"=>{"title"=>"label3"}}]}}}}
#
#  BulkImports::Common::Transformers::GraphqlCleanerTransformer.new.transform(nil, data)
#
#  {"name"=>"test", "fullName"=>"test", "description"=>"test", "labels"=>[{"title"=>"label1"}, {"title"=>"label2"}, {"title"=>"label3"}]}
module BulkImports
  module Common
    module Transformers
      class GraphqlCleanerTransformer
        EDGES = 'edges'
        NODE = 'node'

        def initialize(options = {})
          @options = options
        end

        def transform(_, data)
          return data unless data.is_a?(Hash)

          data = data.dig('data', 'group') || data.dig('data', 'project') || data

          clean_edges_and_nodes(data)
        end

        def clean_edges_and_nodes(data)
          case data
          when Array
            data.map(&method(:clean_edges_and_nodes))
          when Hash
            if data.key?(NODE)
              clean_edges_and_nodes(data[NODE])
            else
              data.transform_values { |value| clean_edges_and_nodes(value.try(:fetch, EDGES, value) || value) }
            end
          else
            data
          end
        end
      end
    end
  end
end
