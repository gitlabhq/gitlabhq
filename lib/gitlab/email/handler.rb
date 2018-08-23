require 'gitlab/email/handler/create_merge_request_handler'
require 'gitlab/email/handler/create_note_handler'
require 'gitlab/email/handler/create_issue_handler'
require 'gitlab/email/handler/unsubscribe_handler'

require 'ee/gitlab/email/handler'

module Gitlab
  module Email
    module Handler
      prepend ::EE::Gitlab::Email::Handler

      def self.handlers
        @handlers ||= load_handlers
      end

      def self.load_handlers
        [
          UnsubscribeHandler,
          CreateNoteHandler,
          CreateMergeRequestHandler,
          CreateIssueHandler
        ]
      end

      def self.for(mail, mail_key)
        handlers.find do |klass|
          handler = klass.new(mail, mail_key)
          break handler if handler.can_handle?
        end
      end
    end
  end
end
