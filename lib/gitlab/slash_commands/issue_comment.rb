# frozen_string_literal: true

module Gitlab
  module SlashCommands
    class IssueComment < IssueCommand
      def self.match(text)
        /\Aissue\s+comment\s+#{Issue.reference_prefix}?(?<iid>\d+)\n*(?<note_body>(.|\n)*)/.match(text)
      end

      def self.help_message
        'issue comment <id> *`⇧ Shift`*+*`↵ Enter`* <comment>'
      end

      def execute(match)
        note_body = match[:note_body].to_s.strip
        issue = find_by_iid(match[:iid])

        return not_found unless issue
        return access_denied unless can_create_note?(issue)

        note = create_note(issue: issue, note: note_body)

        if note.persisted?
          presenter(note).present
        else
          presenter(note).display_errors
        end
      end

      private

      def can_create_note?(issue)
        Ability.allowed?(current_user, :create_note, issue)
      end

      def not_found
        Gitlab::SlashCommands::Presenters::Access.new.not_found
      end

      def access_denied
        Gitlab::SlashCommands::Presenters::Access.new.generic_access_denied
      end

      def create_note(issue:, note:)
        note_params = { noteable: issue, note: note }

        Notes::CreateService.new(project, current_user, note_params).execute
      end

      def presenter(note)
        Gitlab::SlashCommands::Presenters::IssueComment.new(note)
      end
    end
  end
end
