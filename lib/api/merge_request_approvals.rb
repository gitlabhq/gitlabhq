# frozen_string_literal: true

module API
  class MergeRequestApprovals < ::API::Base
    before { authenticate_non_get! }

    feature_category :source_code_management

    helpers ::API::Helpers::MergeRequestsHelpers

    helpers do
      def present_approval(merge_request)
        present merge_request, with: ::API::Entities::MergeRequestApprovals, current_user: current_user
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      requires :merge_request_iid, type: Integer, desc: 'The IID of a merge request'
    end
    resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/merge_requests/:merge_request_iid' do
        # Get the status of the merge request's approvals
        #
        # Parameters:
        #   id (required)                 - The ID of a project
        #   merge_request_iid (required)  - IID of MR
        # Examples:
        #   GET /projects/:id/merge_requests/:merge_request_iid/approvals
        desc 'Retrieve approval state for a merge request' do
          detail 'Retrieves the approval state for a specified merge request. In the response, `approved_by` ' \
            'contains information about all approvers of the merge request, regardless of whether those approvals ' \
            'satisfy any approval rule.'
          success ::API::Entities::MergeRequestApprovals
          failure [
            { code: 404, message: 'Not found' }
          ]
          tags ['merge_request_approvals']
        end
        route_setting :authorization, permissions: :read_merge_request_approval_state, boundary_type: :project
        get 'approvals', urgency: :low do
          merge_request = find_merge_request_with_access(params[:merge_request_iid])

          present_approval(merge_request)
        end

        # Approve a merge request
        #
        # Parameters:
        #   id (required)                 - The ID of a project
        #   merge_request_iid (required)  - IID of MR
        # Examples:
        #   POST /projects/:id/merge_requests/:merge_request_iid/approve
        #
        desc 'Approve merge request' do
          detail 'Approves a specified merge request. The currently authenticated user must be an eligible approver. ' \
            'The `sha` parameter ensures you are approving the current version of the merge request. If defined, ' \
            'the value must match the merge request’s HEAD commit SHA. A mismatch returns a `409 Conflict` response.'
          success code: 201, model: ::API::Entities::MergeRequestApprovals
          failure [
            { code: 304, message: 'Not modified' },
            { code: 404, message: 'Not found' },
            { code: 401, message: 'Unauthorized' }
          ]
          tags ['merge_request_approvals']
        end
        params do
          optional :sha, type: String, desc: 'When present, must have the HEAD SHA of the source branch'
          optional :publish_review, type: Boolean, desc: 'When `true` submits pending review comments'

          use :ee_approval_params
        end
        route_setting :authorization, permissions: :approve_merge_request, boundary_type: :project
        post 'approve', urgency: :low do
          merge_request = find_merge_request_with_access(params[:merge_request_iid], :approve_merge_request)

          check_sha_param!(params, merge_request)

          if params[:publish_review]
            result = ::DraftNotes::PublishService.new(merge_request, current_user).execute

            render_api_error('Failed to publish review', 500) unless result[:status] == :success
          end

          not_modified! if merge_request.approved_by?(current_user)

          success =
            ::MergeRequests::ApprovalService
              .new(project: user_project, current_user: current_user, params: params)
              .execute(merge_request)

          unauthorized! unless success

          present_approval(merge_request)
        end

        desc 'Unapprove a merge request' do
          detail 'Unapproves a merge request. Removes the approval for the currently authenticated user from a ' \
            'specified merge request.'
          success code: 201, model: ::API::Entities::MergeRequestApprovals
          failure [
            { code: 304, message: 'Not modified' },
            { code: 404, message: 'Not found' },
            { code: 401, message: 'Unauthorized' }
          ]
          tags ['merge_request_approvals']
        end
        route_setting :authorization, permissions: :unapprove_merge_request, boundary_type: :project
        post 'unapprove', urgency: :low do
          merge_request = find_merge_request_with_access(params[:merge_request_iid], :approve_merge_request)

          not_modified! unless merge_request.approved_by?(current_user)

          success = ::MergeRequests::RemoveApprovalService
            .new(project: user_project, current_user: current_user)
            .execute(merge_request)

          not_found! unless success

          present_approval(merge_request)
        end

        desc 'Reset approvals for a merge request' do
          detail 'Resets all approvals for a specified merge request. Available only to bot users with a valid ' \
            'project or group token. Human users receive a `401 Unauthorized` response.'
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[merge_request_approvals]
        end
        route_setting :authorization, permissions: :reset_approvals_merge_request, boundary_type: :project
        put 'reset_approvals', urgency: :low do
          merge_request = find_project_merge_request(params[:merge_request_iid])

          unauthorized! unless current_user.can?(:reset_merge_request_approvals, merge_request) &&
            !merge_request.merged?

          merge_request.approvals.delete_all

          merge_request.delete_approval_mergeability_cache

          merge_request.log_approval_deletion_on_merged_or_locked_mr(
            source: 'API::MergeRequestApprovals#reset_approvals',
            current_user: current_user
          )

          status :accepted
        end
      end
    end
  end
end

API::MergeRequestApprovals.prepend_mod_with('API::MergeRequestApprovals')
