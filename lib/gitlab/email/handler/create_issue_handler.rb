
require 'gitlab/email/handler/base_handler'

module Gitlab
  module Email
    module Handler
      class CreateIssueHandler < BaseHandler
        attr_reader :project_namespace, :authentication_token

        def initialize(mail, mail_key)
          super(mail, mail_key)
          @project_namespace, @authentication_token =
            mail_key && mail_key.split('+', 2)
        end

        def can_handle?
          !!(project_namespace && project)
        end

        def execute
          validate_permission!(:create_issue)

          verify_record!(
            create_issue,
            InvalidIssueError,
            "The issue could not be created for the following reasons:"
          )
        end

        def author
          @author ||= User.find_by(authentication_token: authentication_token)
        end

        def project
          @project ||= Project.find_with_namespace(project_namespace)
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
