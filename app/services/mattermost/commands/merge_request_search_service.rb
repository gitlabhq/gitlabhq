module Mattermost
  module Commands
    class MergeRequestSearchService < MergeRequestService
      def execute
        present search_results
      end
    end
  end
end
