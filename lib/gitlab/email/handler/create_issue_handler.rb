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

        HANDLER_REGEX        = /\A.+-(?<project_id>.+)-(?<incoming_email_token>.+)-issue\z/.freeze
        HANDLER_REGEX_LEGACY = /\A(?<project_path>[^\+]*)\+(?<incoming_email_token>.*)\z/.freeze

        def initialize(mail, mail_key)
          super(mail, mail_key)

          if matched = HANDLER_REGEX.match(mail_key.to_s)
            @project_id, @incoming_email_token = matched.captures
          elsif matched = HANDLER_REGEX_LEGACY.match(mail_key.to_s)
            @project_path, @incoming_email_token = matched.captures
          end
        end

        def can_handle?
          incoming_email_token && (project_id || can_handle_legacy_format?)
        end

        def execute
          raise ProjectNotFound unless project

          validate_permission!(:create_issue)

          verify_record!(
            record: create_issue,
            invalid_exception: InvalidIssueError,
            record_name: 'issue')
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def author
          @author ||= User.find_by(incoming_email_token: incoming_email_token)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def project
          @project ||= if project_id
                         Project.find_by_id(project_id)
                       else
                         Project.find_by_full_path(project_path)
                       end
        end

        private

        attr_reader :project_id, :project_path, :incoming_email_token

        def create_issue
          Issues::CreateService.new(
            project,
            author,
            title:       mail.subject,
            description: message_including_reply
          ).execute
        end

        def can_handle_legacy_format?
          project_path && !incoming_email_token.include?('+') && !mail_key.include?(Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX_LEGACY)
        end
      end
    end
  end
end
