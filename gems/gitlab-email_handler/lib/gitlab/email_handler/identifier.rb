# frozen_string_literal: true

require_relative 'matchers/create_note'
require_relative 'matchers/create_issue'
require_relative 'matchers/create_note_on_issuable'
require_relative 'matchers/unsubscribe'
require_relative 'matchers/create_merge_request'
require_relative 'matchers/service_desk'

module Gitlab
  module EmailHandler
    # Identifies which handler an incoming email key belongs to by trying each
    # matcher in the same precedence order as
    # Gitlab::Email::Handler.load_handlers.
    module Identifier
      # Order mirrors Gitlab::Email::Handler.load_handlers.
      MATCHERS = [
        Matchers::CreateNote,
        Matchers::CreateIssue,
        Matchers::CreateNoteOnIssuable,
        Matchers::Unsubscribe,
        Matchers::CreateMergeRequest,
        Matchers::ServiceDesk
      ].freeze

      class << self
        def matchers
          @matchers ||= MATCHERS.map(&:new)
        end

        # @param mail_key [String]
        # @return [Gitlab::EmailHandler::Identification, nil]
        def call(mail_key)
          return if mail_key.nil?

          matchers.each do |matcher|
            result = matcher.match(mail_key)
            return result if result
          end

          nil
        end

        # Convenience: returns an Identification for a specific handler only.
        # Used by the GitLab handlers which already know their own type.
        def for_handler(handler_name, mail_key)
          matcher = matchers.find { |m| m.handler_name == handler_name }
          matcher&.match(mail_key)
        end
      end
    end
  end
end
