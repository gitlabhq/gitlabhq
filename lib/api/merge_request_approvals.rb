# frozen_string_literal: true

module API
  class MergeRequestApprovals < ::API::Base
    before { authenticate_non_get! }

    feature_category :source_code_management

    helpers do
      params :ee_approval_params do
      end

      def present_approval(merge_request)
        present merge_request, with: ::API::Entities::MergeRequestApprovals, current_user: current_user
      end
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
        desc 'List approvals for merge request'
        get 'approvals' do
          not_found!("Merge Request") unless can?(current_user, :read_merge_request, user_project)

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
        desc 'Approve a merge request'
        params do
          optional :sha, type: String, desc: 'When present, must have the HEAD SHA of the source branch'

          use :ee_approval_params
        end
        post 'approve' do
          merge_request = find_merge_request_with_access(params[:merge_request_iid], :approve_merge_request)

          check_sha_param!(params, merge_request)

          success =
            ::MergeRequests::ApprovalService
              .new(project: user_project, current_user: current_user, params: params)
              .execute(merge_request)

          unauthorized! unless success

          present_approval(merge_request)
        end

        desc 'Remove an approval from a merge request'
        post 'unapprove' do
          merge_request = find_merge_request_with_access(params[:merge_request_iid], :approve_merge_request)

          success = ::MergeRequests::RemoveApprovalService
            .new(project: user_project, current_user: current_user)
            .execute(merge_request)

          not_found! unless success

          present_approval(merge_request)
        end
      end
    end
  end
end

API::MergeRequestApprovals.prepend_mod_with('API::MergeRequestApprovals')
