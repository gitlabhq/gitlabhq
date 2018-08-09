# frozen_string_literal: true

class MergeRequestCreateEntity < Grape::Entity
  expose :iid

  expose :url do |merge_request|
    Gitlab::UrlBuilder.build(merge_request)
  end
end
