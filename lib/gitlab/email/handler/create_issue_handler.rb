require 'gitlab/email/handler/base_handler'

module Gitlab
  module Email
    module Handler
      class CreateIssueHandler < BaseHandler
        include ReplyProcessing
        attr_reader :project_path, :incoming_email_token

        def initialize(mail, mail_key)
          super(mail, mail_key)
          @project_path, @incoming_email_token =
            mail_key && mail_key.split('+', 2)
        end

        def can_handle?
          !incoming_email_token.nil? && !incoming_email_token.include?("+") && !mail_key.include?(Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX)
        end

        def execute
          raise ProjectNotFound unless project

          validate_permission!(:create_issue)

          verify_record!(
            record: create_issue,
            invalid_exception: InvalidIssueError,
            record_name: 'issue')
        end

        def author
          @author ||= User.find_by(incoming_email_token: incoming_email_token)
        end

        def project
          @project ||= Project.find_by_full_path(project_path)
        end

        def metrics_params
          super.merge(project: project&.full_path)
        end

        private

        def create_issue
          Issues::CreateService.new(
            project,
            author,
            title:       mail.subject,
            description: message
          ).execute
        end
      end
    end
  end
end
