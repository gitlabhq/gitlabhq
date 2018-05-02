require 'gitlab/email/handler/base_handler'
require 'gitlab/email/handler/reply_processing'

module Gitlab
  module Email
    module Handler
      class CreateMergeRequestHandler < BaseHandler
        include ReplyProcessing
        attr_reader :project_path, :incoming_email_token

        def initialize(mail, mail_key)
          super(mail, mail_key)

          if m = /\A([^\+]*)\+merge-request\+(.*)/.match(mail_key.to_s)
            @project_path, @incoming_email_token = m.captures
          end
        end

        def can_handle?
          @project_path && @incoming_email_token
        end

        def execute
          raise ProjectNotFound unless project

          validate_permission!(:create_merge_request_in)
          validate_permission!(:create_merge_request_from)

          verify_record!(
            record: create_merge_request,
            invalid_exception: InvalidMergeRequestError,
            record_name: 'merge_request')
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

        def create_merge_request
          merge_request = MergeRequests::BuildService.new(project, author, merge_request_params).execute

          if merge_request.errors.any?
            merge_request
          else
            MergeRequests::CreateService.new(project, author).create(merge_request)
          end
        end

        def merge_request_params
          params = {
            source_project_id: project.id,
            source_branch: mail.subject,
            target_project_id: project.id
          }
          params[:description] = message if message.present?
          params
        end
      end
    end
  end
end
