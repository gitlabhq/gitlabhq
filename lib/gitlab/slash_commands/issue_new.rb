# frozen_string_literal: true

module Gitlab
  module SlashCommands
    class IssueNew < IssueCommand
      def self.match(text)
        # we can not match \n with the dot by passing the m modifier as than
        # the title and description are not separated
        /\Aissue\s+(new|create)\s+(?<title>[^\n]*)\n*(?<description>(.|\n)*)/.match(text)
      end

      def self.help_message
        'issue new <title> *`⇧ Shift`*+*`↵ Enter`* <description>'
      end

      def self.allowed?(project, user)
        can?(user, :create_issue, project)
      end

      def execute(match)
        title = match[:title]
        description = match[:description].to_s.rstrip

        issue = create_issue(title: title, description: description)

        if issue.persisted?
          presenter(issue).present
        else
          presenter(issue).display_errors
        end
      end

      private

      def create_issue(title:, description:)
        Issues::CreateService.new(project: project, current_user: current_user, params: { title: title, description: description }, spam_params: nil).execute
      end

      def presenter(issue)
        Gitlab::SlashCommands::Presenters::IssueNew.new(issue)
      end
    end
  end
end
