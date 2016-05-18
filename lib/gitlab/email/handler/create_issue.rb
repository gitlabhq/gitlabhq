
require 'gitlab/email/handler'

module Gitlab
  module Email
    class Handler
      class CreateIssue < Handler
        def can_handle?
          !!project
        end

        def execute
          # Must be private project without access
          raise ProjectNotFound unless author.can?(:read_project, project)

          validate_permission!(:create_issue)
          validate_authentication_token!

          verify_record(
            create_issue,
            InvalidIssueError,
            "The issue could not be created for the following reasons:"
          )
        end

        def author
          @author ||= mail.from.find do |email|
            user = User.find_by_any_email(email)
            break user if user
          end
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

        def validate_authentication_token!
          raise UserNotAuthorizedError unless author.authentication_token ==
                                                authentication_token
        end
      end
    end
  end
end
