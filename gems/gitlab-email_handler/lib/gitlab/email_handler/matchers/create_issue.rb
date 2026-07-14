# frozen_string_literal: true

require_relative 'base'

module Gitlab
  module EmailHandler
    module Matchers
      # Mirrors Gitlab::Email::Handler::CreateIssueHandler.
      #   incoming+gitlab-org-gitlab-ce-20-Author_Token-issue@incoming.gitlab.com
      #   incoming+gitlab-org/gitlab-ce+Author_Token@incoming.gitlab.com (legacy)
      class CreateIssue < Base
        HANDLER_REGEX = /\A#{ReplyKey::HANDLER_ACTION_BASE_REGEX}-(?<incoming_email_token>.+)-issue\z/
        HANDLER_REGEX_LEGACY = /\A(?<project_path>[^+]*)\+(?<incoming_email_token>.*)\z/

        def match(mail_key)
          key = mail_key.to_s

          matched = HANDLER_REGEX.match(key) unless mail_key&.include?('/')
          if matched
            return identification(
              project_slug: matched[:project_slug],
              project_id: matched[:project_id]&.to_i,
              incoming_email_token: matched[:incoming_email_token]
            )
          end

          matched = HANDLER_REGEX_LEGACY.match(key)
          return unless matched

          project_path = matched[:project_path]
          incoming_email_token = matched[:incoming_email_token]
          return unless can_handle_legacy_format?(project_path, incoming_email_token, key)

          identification(
            project_path: project_path,
            incoming_email_token: incoming_email_token
          )
        end

        def handler_name
          :create_issue
        end

        private

        def can_handle_legacy_format?(project_path, incoming_email_token, mail_key)
          project_path &&
            incoming_email_token &&
            !incoming_email_token.include?('+') &&
            !mail_key.include?(ReplyKey::UNSUBSCRIBE_SUFFIX_LEGACY)
        end
      end
    end
  end
end
