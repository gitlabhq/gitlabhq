# frozen_string_literal: true

module API
  module Entities
    class UserCounts < Grape::Entity
      expose(
        :assigned_open_merge_requests_count, # @deprecated
        as: :merge_requests,
        documentation: { type: 'integer', example: 10 }
      )
      expose :assigned_open_issues_count, as: :assigned_issues, documentation: { type: 'integer', example: 10 }
      expose(
        :assigned_open_merge_requests_count,
        as: :assigned_merge_requests,
        documentation: { type: 'integer', example: 10 }
      )
      expose(
        :review_requested_open_merge_requests_count,
        as: :review_requested_merge_requests,
        documentation: { type: 'integer', example: 10 }
      )
      expose :todos_pending_count, as: :todos, documentation: { type: 'integer', example: 10 }
    end
  end
end
