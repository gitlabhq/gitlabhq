# frozen_string_literal: true

module MergeRequestResourceEvent
  extend ActiveSupport::Concern

  included do
    belongs_to :merge_request
    delegate :project, to: :merge_request, prefix: true, allow_nil: true

    scope :by_merge_request, ->(merge_request) { where(merge_request_id: merge_request.id) }
    scope :with_merge_request_project_ordered, -> { includes(merge_request: :target_project).order(id: :asc) }
  end
end
