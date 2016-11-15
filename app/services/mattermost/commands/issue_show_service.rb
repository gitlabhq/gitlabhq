module Mattermost
  module Commands
    class IssueShowService < IssueService
      def execute
        return Mattermost::Messages.not_available unless available?

        issue = find_by_iid(iid)
        present issue
      end
    end
  end
end
