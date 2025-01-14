# frozen_string_literal: true

module Gitlab
  module SlashCommands
    class IssueNew < IssueCommand
      def self.match(text)
        # we can not match \n with the dot by passing the m modifier as then
        # the title and description are not separated
        /\Aissue\s+(?:new|create)\s+(?<title>[^\n]*)\n*(?<description>(?:.|\n)*)/.match(text)
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

        result = create_issue(title: title, description: description)

        if result.success?
          presenter(result[:issue]).present
        elsif result[:issue]
          presenter(result[:issue]).display_errors
        else
          Gitlab::SlashCommands::Presenters::Error.new(
            result.errors.join(', ')
          ).message
        end
      end

      private

      def create_issue(title:, description:)
        ::Issues::CreateService.new(container: project, current_user: current_user, params: { title: title, description: description }, perform_spam_check: false).execute
      end

      def presenter(issue)
        Gitlab::SlashCommands::Presenters::IssueNew.new(issue)
      end
    end
  end
end
