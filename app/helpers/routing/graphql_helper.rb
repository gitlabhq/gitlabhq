# frozen_string_literal: true

module Routing
  module GraphqlHelper
    def graphql_etag_pipeline_path(pipeline)
      [api_graphql_path, "pipelines/id/#{pipeline.id}"].join(':')
    end

    def graphql_etag_pipeline_sha_path(sha)
      [api_graphql_path, "pipelines/sha/#{sha}"].join(':')
    end
  end
end
