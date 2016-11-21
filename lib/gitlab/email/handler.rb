require 'gitlab/email/handler/create_note_handler'
require 'gitlab/email/handler/create_issue_handler'

module Gitlab
  module Email
    module Handler
      HANDLERS = [CreateNoteHandler, CreateIssueHandler]

      def self.for(mail, mail_key)
        HANDLERS.find do |klass|
          handler = klass.new(mail, mail_key)
          break handler if handler.can_handle?
        end
      end
    end
  end
end
