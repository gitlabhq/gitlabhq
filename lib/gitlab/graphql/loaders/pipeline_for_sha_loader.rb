# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class PipelineForShaLoader
        attr_accessor :project, :sha

        def initialize(project, sha)
          @project, @sha = project, sha
        end

        def find_last
          BatchLoader::GraphQL.for(sha).batch(key: project) do |shas, loader, args|
            pipelines = args[:key].ci_pipelines.latest_for_shas(shas)

            pipelines.each do |pipeline|
              loader.call(pipeline.sha, pipeline)
            end
          end
        end
      end
    end
  end
end
