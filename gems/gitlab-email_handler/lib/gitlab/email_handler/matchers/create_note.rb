# frozen_string_literal: true

require_relative 'base'

module Gitlab
  module EmailHandler
    module Matchers
      # Mirrors Gitlab::Email::Handler::CreateNoteHandler.
      #   incoming+<reply_key>@incoming.gitlab.com
      class CreateNote < Base
        HANDLER_REGEX = /\A#{ReplyKey::FULL_REPLY_KEY_REGEX}\z/

        def match(mail_key)
          matched = HANDLER_REGEX.match(mail_key.to_s)
          return unless matched

          identification(
            reply_key: matched[:reply_key],
            namespace_id: matched[:namespace_id],
            legacy_key: matched[:legacy_key]
          )
        end

        def handler_name
          :create_note
        end
      end
    end
  end
end
