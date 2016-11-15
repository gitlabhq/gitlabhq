module Mattermost
  module Commands
    class MergeRequestShowService < Mattermost::Commands::BaseService
      def execute
        return Mattermost::Messages.not_available unless available?

        merge_request = find_by_iid(iid)
        present merge_request
      end
    end
  end
end
