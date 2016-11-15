module Mattermost
  module Commands
    class MergeRequestService < Mattermost::Commands::BaseService
      def execute
        return Mattermost::Messages::MergeRequests.not_available unless available?

        Mattermost::Messages::IssuePresenter.present search_results
      end
    end
  end
end
