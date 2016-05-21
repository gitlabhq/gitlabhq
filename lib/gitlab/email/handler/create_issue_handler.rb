
require 'gitlab/email/handler/base_handler'

module Gitlab
  module Email
    module Handler
      class CreateIssueHandler < BaseHandler
        def can_handle?
          !!project
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
        def authentication_token
          mail_key[/[^\+]+$/]
        end

        def project_namespace
          mail_key[/^[^\+]+/]
        end

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
