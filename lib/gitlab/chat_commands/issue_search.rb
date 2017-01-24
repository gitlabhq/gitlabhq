module Gitlab
  module ChatCommands
    class IssueSearch < IssueCommand
      def self.match(text)
        /\Aissue\s+search\s+(?<query>.*)/.match(text)
      end

      def self.help_message
        "issue search <your query>"
      end

      def execute(match)
        collection.search(match[:query]).limit(QUERY_LIMIT)
      end
    end
  end
end
