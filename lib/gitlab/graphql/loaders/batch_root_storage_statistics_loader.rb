# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class BatchRootStorageStatisticsLoader
        attr_reader :namespace_id

        def initialize(namespace_id)
          @namespace_id = namespace_id
        end

        def find
          BatchLoader::GraphQL.for(namespace_id).batch do |namespace_ids, loader|
            Namespace::RootStorageStatistics.for_namespace_ids(namespace_ids).each do |statistics|
              loader.call(statistics.namespace_id, statistics)
            end
          end
        end
      end
    end
  end
end
