# frozen_string_literal: true

module Gitlab
  module Email
    module Handler
      class BaseHandler
        attr_reader :mail, :mail_key

        HANDLER_ACTION_BASE_REGEX = /(?<project_slug>.+)-(?<project_id>\d+)/

        def initialize(mail, mail_key)
          @mail = mail
          @mail_key = mail_key
        end

        def can_handle?
          raise NotImplementedError
        end

        def execute
          raise NotImplementedError
        end

        def metrics_params
          { handler: self.class.name }
        end

        # Each handler should use it's own metric event.  Otherwise there
        # is a possibility that within the same Sidekiq process, that same
        # event with different metrics_params will cause Prometheus to
        # throw an error
        def metrics_event
          raise NotImplementedError
        end

        private

        def reopen_issue_on_external_participant_note(noteable:, author:, project:, support_bot:)
          return unless noteable.respond_to?(:closed?)
          return unless noteable.closed?
          return unless author.support_bot?
          return unless project&.service_desk_setting&.reopen_issue_on_external_participant_note?

          ::Notes::CreateService.new(
            project,
            support_bot,
            noteable: noteable,
            note: build_reopen_message(noteable),
            confidential: true
          ).execute
        end

        def build_reopen_message(noteable)
          translated_text = s_(
            "ServiceDesk|This issue has been reopened because it received a new comment from an external participant."
          )

          "#{assignees_references(noteable)} :wave: #{translated_text}\n/reopen".lstrip
        end

        def assignees_references(noteable)
          return unless noteable.assignees.any?

          noteable.assignees.map(&:to_reference).join(' ')
        end

        def from_address
          (mail.reply_to || []).first || mail.from.first || mail.sender
        end
      end
    end
  end
end
