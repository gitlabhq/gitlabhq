# frozen_string_literal: true

module Gitlab
  module SlashCommands
    class IssueClose < IssueCommand
      def self.match(text)
        /\Aissue\s+close\s+#{Issue.reference_prefix}?(?<iid>\d+)/.match(text)
      end

      def self.help_message
        "issue close <id>"
      end

      def self.allowed?(project, user)
        can?(user, :update_issue, project)
      end

      def execute(match)
        issue = find_by_iid(match[:iid])

        return not_found unless issue
        return presenter(issue).already_closed if issue.closed?

        close_issue(issue: issue)

        presenter(issue).present
      end

      private

      def close_issue(issue:)
        ::Issues::CloseService.new(container: project, current_user: current_user).execute(issue)
      end

      def presenter(issue)
        Gitlab::SlashCommands::Presenters::IssueClose.new(issue)
      end

      def not_found
        Gitlab::SlashCommands::Presenters::Access.new.not_found
      end
    end
  end
end
