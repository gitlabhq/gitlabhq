module Gitlab
  module ChatCommands
    class IssueShow < IssueCommand
      def self.match(text)
        /\Aissue\s+show\s+#{Issue.reference_prefix}?(?<iid>\d+)/.match(text)
      end

      def self.help_message
        "issue show <id>"
      end

      def execute(match)
        issue = find_by_iid(match[:iid])
        Gitlab::ChatCommands::Presenters::ShowIssue.new(issue).present
      end
    end
  end
end
