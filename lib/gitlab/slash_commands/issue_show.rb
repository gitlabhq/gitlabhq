# frozen_string_literal: true

module Gitlab
  module SlashCommands
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
          Gitlab::SlashCommands::Presenters::IssueShow.new(issue).present
        else
          Gitlab::SlashCommands::Presenters::Access.new.not_found
        end
      end
    end
  end
end
