require 'gitlab/email/handler/create_note_handler'
require 'gitlab/email/handler/create_issue_handler'

module Gitlab
  module Email
    module Handler
      def self.for(mail, mail_key)
        [CreateNoteHandler, CreateIssueHandler].find do |klass|
          handler = klass.new(mail, mail_key)
          break handler if handler.can_handle?
        end
      end
    end
  end
end
