module Gitlab
  module ChatCommands
    class IssueSearch < IssueCommand
      def self.match(text)
        /\Aissue\s+search\s+(?<query>.*)/.match(text)
      end

      def self.help_message
        "issue search <query>"
      end

      def execute(match)
        present search_results(match[:query])
      end
    end
  end
end
