# frozen_string_literal: true

require 'gitlab/email/handler/base_handler'
require 'gitlab/email/handler/reply_processing'

# handles merge request creation emails with these formats:
#   incoming+gitlab-org-gitlab-ce-20-Author_Token12345678-merge-request@incoming.gitlab.com
#   incoming+gitlab-org/gitlab-ce+merge-request+Author_Token12345678@incoming.gitlab.com (legacy)
module Gitlab
  module Email
    module Handler
      class CreateMergeRequestHandler < BaseHandler
        include ReplyProcessing

        HANDLER_REGEX        = /\A#{HANDLER_ACTION_BASE_REGEX}-(?<incoming_email_token>.+)-merge-request\z/.freeze
        HANDLER_REGEX_LEGACY = /\A(?<project_path>[^\+]*)\+merge-request\+(?<incoming_email_token>.*)/.freeze

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
          incoming_email_token && (project_id || project_path)
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

        # rubocop: disable CodeReuse/ActiveRecord
        def author
          @author ||= User.find_by(incoming_email_token: incoming_email_token)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def metrics_params
          super.merge(includes_patches: patch_attachments.any?)
        end

        def metrics_event
          :receive_email_create_merge_request
        end

        private

        def build_merge_request
          MergeRequests::BuildService.new(project: project, current_user: author, params: merge_request_params).execute
        end

        def create_merge_request
          merge_request = build_merge_request

          if patch_attachments.any?
            apply_patches_to_source_branch(start_branch: merge_request.target_branch)
            remove_patch_attachments
            # Rebuild the merge request as the source branch might just have
            # been created, so we should re-validate.
            merge_request = build_merge_request
          end

          if merge_request.errors.any?
            merge_request
          else
            MergeRequests::CreateService.new(project: project, current_user: author).create(merge_request)
          end
        end

        def merge_request_params
          params = {
            source_project_id: project.id,
            source_branch: source_branch,
            target_project_id: project.id
          }
          params[:description] = message if message.present?
          params
        end

        def apply_patches_to_source_branch(start_branch:)
          patches = patch_attachments.map { |patch| patch.body.decoded }

          result = Commits::CommitPatchService
                     .new(project, author, branch_name: source_branch, patches: patches, start_branch: start_branch)
                     .execute

          if result[:status] != :success
            message = "Could not apply patches to #{source_branch}:\n#{result[:message]}"
            raise InvalidAttachment, message
          end
        end

        def remove_patch_attachments
          patch_attachments.each { |patch| mail.parts.delete(patch) }
          # reset the message, so it needs to be reprocessed when the attachments
          # have been modified
          @message = nil
        end

        def patch_attachments
          @patches ||= mail.attachments
                         .select { |attachment| attachment.filename.ends_with?('.patch') }
                         .sort_by(&:filename)
        end

        def source_branch
          @source_branch ||= mail.subject
        end
      end
    end
  end
end
