# frozen_string_literal: true

module TodosDestroyer
  class ConfidentialIssueWorker
    include ApplicationWorker
    include TodosDestroyerQueue

    def perform(issue_id = nil, project_id = nil)
      ::Todos::Destroy::ConfidentialIssueService.new(issue_id: issue_id, project_id: project_id).execute
    end
  end
end
