module Gitlab
  module ChatCommands
    class IssueShow < IssueCommand
      def self.match(text)
        /\Aissue\s+show\s+(?<iid>\d+)/.match(text)
      end

      def self.help_message
        "issue show <id>"
      end

      def execute(match)
        present find_by_iid(match[:iid])
      end
    end
  end
end
