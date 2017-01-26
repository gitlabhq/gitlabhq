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

        if issue
          Gitlab::ChatCommands::Presenters::IssueShow.new(issue).present
        else
          Gitlab::ChatCommands::Presenters::Access.new.not_found
        end
      end
    end
  end
end
