# frozen_string_literal: true

module API
  module Entities
    class MergeRequestSimple < IssuableEntity
      expose :title, documentation: { type: 'string', example: 'Test MR 1580978354' }
      expose :web_url,
        documentation: {
          type: 'string', example: 'http://local.gitlab.test:8181/root/merge-train-race-condition/-/merge_requests/59'
        } do |merge_request, options|
        Gitlab::UrlBuilder.build(merge_request)
      end
    end
  end
end
