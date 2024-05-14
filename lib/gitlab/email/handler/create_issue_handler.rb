# frozen_string_literal: true

require 'gitlab/email/handler/base_handler'

# handles issue creation emails with these formats:
#   incoming+gitlab-org-gitlab-ce-20-Author_Token12345678-issue@incoming.gitlab.com
#   incoming+gitlab-org/gitlab-ce+Author_Token12345678@incoming.gitlab.com (legacy)
module Gitlab
  module Email
    module Handler
      class CreateIssueHandler < BaseHandler
        include ReplyProcessing

        HANDLER_REGEX        = /\A#{HANDLER_ACTION_BASE_REGEX}-(?<incoming_email_token>.+)-issue\z/
        HANDLER_REGEX_LEGACY = /\A(?<project_path>[^\+]*)\+(?<incoming_email_token>.*)\z/

        def initialize(mail, mail_key)
          super(mail, mail_key)

          if !mail_key&.include?('/') && (matched = HANDLER_REGEX.match(mail_key.to_s))
            @project_slug         = matched[:project_slug]
            @project_id           = matched[:project_id]&.to_i
            @incoming_email_token = matched[:incoming_email_token]
          elsif matched = HANDLER_REGEX_LEGACY.match(mail_key.to_s)
            @project_path         = matched[:project_path]
            @incoming_email_token = matched[:incoming_email_token]
          end
        end

        def can_handle?
          incoming_email_token && (project_id || can_handle_legacy_format?)
        end

        def execute
          raise ProjectNotFound unless project

          validate_permission!(:create_issue)

          result = create_issue
          issue = result[:issue]

          # issue won't be present only on unrecoverable errors
          raise InvalidIssueError, result.errors.join(', ') if result.error? && issue.blank?

          verify_record!(
            record: issue,
            invalid_exception: InvalidIssueError,
            record_name: 'issue')
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def author
          @author ||= User.find_by(incoming_email_token: incoming_email_token)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def metrics_event
          :receive_email_create_issue
        end

        private

        def create_issue
          ::Issues::CreateService.new(
            container: project,
            current_user: author,
            params: {
              title: mail.subject,
              description: message_including_reply_or_only_quotes
            },
            perform_spam_check: false
          ).execute
        end

        def can_handle_legacy_format?
          project_path && incoming_email_token.exclude?('+') && mail_key.exclude?(Gitlab::Email::Common::UNSUBSCRIBE_SUFFIX_LEGACY)
        end
      end
    end
  end
end
