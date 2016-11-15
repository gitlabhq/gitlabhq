module Mattermost
  module Commands
    class IssueShowService < Mattermost::Commands::BaseService
      def execute
        return Mattermost::Messages::Issues.not_available unless available?

        issue = find_by_iid(iid)

        present issue
      end
    end
  end
end
