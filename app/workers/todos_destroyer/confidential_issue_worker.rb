# frozen_string_literal: true

module TodosDestroyer
  class ConfidentialIssueWorker
    include ApplicationWorker
    include TodosDestroyerQueue

    def perform(issue_id)
      ::Todos::Destroy::ConfidentialIssueService.new(issue_id).execute
    end
  end
end
