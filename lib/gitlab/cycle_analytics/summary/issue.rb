# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      class Issue < Base
        def initialize(project:, from:, to: nil, current_user:)
          @project = project
          @from = from
          @to = to
          @current_user = current_user
        end

        def title
          n_('New Issue', 'New Issues', value.to_i)
        end

        def value
          @value ||= Value::PrettyNumeric.new(issues_count)
        end

        private

        def issues_count
          IssuesFinder
            .new(@current_user, project_id: @project.id, created_after: @from, created_before: @to)
            .execute
            .count
        end
      end
    end
  end
end
