module Mattermost
  module Commands
    class IssueShowService < IssueService
      def execute
        present find_by_iid
      end
    end
  end
end
