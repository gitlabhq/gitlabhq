module Mattermost
  module Commands
    class IssueSearchService < IssueService
      def execute
        present search_results
      end
    end
  end
end
