# frozen_string_literal: true

module API
  module Entities
    module Ci
      # Slim merge request payload for pipeline lists; deliberately excludes
      # the description to keep list responses small.
      class PipelineMergeRequest < Grape::Entity
        expose :iid, documentation: { type: 'Integer', example: 14 }
        expose :title, documentation: { type: 'String', example: 'Add rate limiting to the public API' }
        expose :web_url,
          documentation: {
            type: 'String',
            example: 'https://gitlab.example.com/foo/bar/-/merge_requests/14'
          } do |merge_request, _options|
          Gitlab::UrlBuilder.build(merge_request)
        end
      end
    end
  end
end
