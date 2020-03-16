# frozen_string_literal: true

module API
  module Entities
    class MilestoneWithStats < Entities::Milestone
      expose :issue_stats do
        expose :total_issues_count, as: :total
        expose :closed_issues_count, as: :closed
      end
    end
  end
end
