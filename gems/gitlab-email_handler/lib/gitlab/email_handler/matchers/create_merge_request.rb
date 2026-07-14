# frozen_string_literal: true

require_relative 'base'

module Gitlab
  module EmailHandler
    module Matchers
      # Mirrors Gitlab::Email::Handler::CreateMergeRequestHandler.
      #   incoming+gitlab-org-gitlab-ce-20-Author_Token-merge-request@incoming.gitlab.com
      #   incoming+gitlab-org/gitlab-ce+merge-request+Author_Token@incoming.gitlab.com (legacy)
      class CreateMergeRequest < Base
        HANDLER_REGEX = /\A#{ReplyKey::HANDLER_ACTION_BASE_REGEX}-(?<incoming_email_token>.+)-merge-request\z/
        HANDLER_REGEX_LEGACY = /\A(?<project_path>[^+]*)\+merge-request\+(?<incoming_email_token>.*)/

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

          identification(
            project_path: matched[:project_path],
            incoming_email_token: matched[:incoming_email_token]
          )
        end

        def handler_name
          :create_merge_request
        end
      end
    end
  end
end
