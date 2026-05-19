# frozen_string_literal: true

module API
  module Entities
    class MilestoneWithStats < Entities::Milestone
      expose :issue_stats, documentation: { type: 'Hash' } do
        expose :total_issues_count, as: :total, documentation: { type: 'Integer', example: 10 }
        expose :closed_issues_count, as: :closed, documentation: { type: 'Integer', example: 5 }
      end
    end
  end
end
