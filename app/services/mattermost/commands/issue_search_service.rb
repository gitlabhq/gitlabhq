module Mattermost
  module Commands
    class IssueShowService < IssueService
      def execute
        return Mattermost::Messages::Issues.not_available unless available?

        present search_results
      end
    end
  end
end
