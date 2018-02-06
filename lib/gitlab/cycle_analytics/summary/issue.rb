module Gitlab
  module CycleAnalytics
    module Summary
      class Issue < Base
        def initialize(project:, from:, current_user:)
          @project = project
          @from = from
          @current_user = current_user
        end

        def title
          n_('New Issue', 'New Issues', value)
        end

        def value
          @value ||= IssuesFinder.new(@current_user, project_id: @project.id).execute.created_after(@from).count
        end
      end
    end
  end
end
