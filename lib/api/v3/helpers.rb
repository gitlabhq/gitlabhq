module API
  module V3
    module Helpers
      def find_project_issue(id)
        IssuesFinder.new(current_user, project_id: user_project.id).find(id)
      end
    end
  end
end
