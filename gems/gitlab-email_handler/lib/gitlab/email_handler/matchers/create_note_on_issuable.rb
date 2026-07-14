# frozen_string_literal: true

require_relative 'base'

module Gitlab
  module EmailHandler
    module Matchers
      # Mirrors Gitlab::Email::Handler::CreateNoteOnIssuableHandler.
      #   incoming+gitlab-org-gitlab-ce-20-Author_Token-issue-34@incoming.gitlab.com
      class CreateNoteOnIssuable < Base
        HANDLER_REGEX =
          /\A#{ReplyKey::HANDLER_ACTION_BASE_REGEX}-(?<incoming_email_token>.+)-issue-(?<issuable_iid>\d+)\z/

        def match(mail_key)
          matched = HANDLER_REGEX.match(mail_key.to_s)
          return unless matched

          identification(
            project_slug: matched[:project_slug],
            project_id: matched[:project_id]&.to_i,
            incoming_email_token: matched[:incoming_email_token],
            issuable_iid: matched[:issuable_iid]&.to_i
          )
        end

        def handler_name
          :create_note_on_issuable
        end
      end
    end
  end
end
