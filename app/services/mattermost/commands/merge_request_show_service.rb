module Mattermost
  module Commands
    class MergeRequestShowService < MergeRequestService
      def execute
        present find_by_iid
      end
    end
  end
end
