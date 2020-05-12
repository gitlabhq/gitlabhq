# frozen_string_literal: true

module MergeRequestResourceEvent
  extend ActiveSupport::Concern

  included do
    belongs_to :merge_request

    scope :by_merge_request, ->(merge_request) { where(merge_request_id: merge_request.id) }
  end
end
