# frozen_string_literal: true

module API
  module Helpers
    module IssuesHelpers
      def self.update_params_at_least_one_of
        [
          :assignee_id,
          :assignee_ids,
          :confidential,
          :created_at,
          :description,
          :discussion_locked,
          :due_date,
          :labels,
          :milestone_id,
          :state_event,
          :title
        ]
      end
    end
  end
end
