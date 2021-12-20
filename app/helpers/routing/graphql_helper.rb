# frozen_string_literal: true

module Routing
  module GraphqlHelper
    def graphql_etag_pipeline_path(pipeline)
      [api_graphql_path, "pipelines/id/#{pipeline.id}"].join(':')
    end

    def graphql_etag_pipeline_sha_path(sha)
      [api_graphql_path, "pipelines/sha/#{sha}"].join(':')
    end

    def graphql_etag_project_on_demand_scan_counts_path(project)
      [api_graphql_path, "on_demand_scan/counts/#{project.full_path}"].join(':')
    end
  end
end
