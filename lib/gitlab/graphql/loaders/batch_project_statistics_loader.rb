# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class BatchProjectStatisticsLoader
        attr_reader :project_id

        def initialize(project_id)
          @project_id = project_id
        end

        def find
          BatchLoader::GraphQL.for(project_id).batch do |project_ids, loader|
            ProjectStatistics.for_project_ids(project_ids).each do |statistics|
              loader.call(statistics.project_id, statistics)
            end
          end
        end
      end
    end
  end
end
