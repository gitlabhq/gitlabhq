# frozen_string_literal: true

module API
  module Entities
    class MergeRequestSimple < IssuableEntity
      expose :title
      expose :web_url do |merge_request, options|
        Gitlab::UrlBuilder.build(merge_request)
      end
    end
  end
end
