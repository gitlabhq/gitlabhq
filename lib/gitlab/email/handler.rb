# frozen_string_literal: true

module Gitlab
  module Email
    module Handler
      def self.handlers
        @handlers ||= load_handlers
      end

      def self.load_handlers
        [
          CreateNoteHandler,
          CreateIssueHandler,
          CreateNoteOnIssuableHandler,
          UnsubscribeHandler,
          CreateMergeRequestHandler,
          ServiceDeskHandler
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
