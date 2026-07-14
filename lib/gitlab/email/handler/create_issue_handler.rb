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

        def self.gem_handler
          :create_issue
        end

        def execute
          raise ProjectNotFound unless project

          log_email_handler
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

        def parent_namespace
          project.project_namespace
        end

        def additional_log_data
          { Labkit::Fields::GL_PROJECT_ID => project.id }
        end

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
      end
    end
  end
end
