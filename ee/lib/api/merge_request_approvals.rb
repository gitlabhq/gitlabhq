module API
  class MergeRequestApprovals < ::Grape::API
    before { authenticate_non_get! }

    helpers do
      def handle_merge_request_errors!(errors)
        if errors.has_key? :project_access
          error!(errors[:project_access], 422)
        elsif errors.has_key? :branch_conflict
          error!(errors[:branch_conflict], 422)
        elsif errors.has_key? :validate_fork
          error!(errors[:validate_fork], 422)
        elsif errors.has_key? :validate_branches
          conflict!(errors[:validate_branches])
        elsif errors.has_key? :base
          error!(errors[:base], 422)
        end

        render_api_error!(errors, 400)
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
      requires :merge_request_iid, type: Integer, desc: 'The IID of a merge request'
    end
    resource :projects, requirements: ::API::API::PROJECT_ENDPOINT_REQUIREMENTS do
      segment ':id/merge_requests/:merge_request_iid' do
        # Get the status of the merge request's approvals
        #
        # Parameters:
        #   id (required)                 - The ID of a project
        #   merge_request_iid (required)  - IID of MR
        # Examples:
        #   GET /projects/:id/merge_requests/:merge_request_iid/approvals
        #
        desc 'List approvals for merge request' do
          success Entities::MergeRequestApprovals
        end
        get 'approvals' do
          merge_request = find_merge_request_with_access(params[:merge_request_iid])

          present merge_request, with: Entities::MergeRequestApprovals, current_user: current_user
        end

        desc 'Change approval-related configuration' do
          detail 'This feature was introduced in 10.6'
          success Entities::MergeRequestApprovals
        end
        params do
          requires :approvals_required, type: Integer, desc: 'The amount of approvals required. Must be higher than the project approvals'
        end
        post 'approvals' do
          merge_request = find_merge_request_with_access(params[:merge_request_iid], :update_merge_request)

          error!('Overriding approvals is disabled', 422) if merge_request.project.disable_overriding_approvers_per_merge_request

          merge_request = ::MergeRequests::UpdateService.new(user_project, current_user, approvals_before_merge: params[:approvals_required]).execute(merge_request)

          if merge_request.valid?
            present merge_request, with: Entities::MergeRequestApprovals, current_user: current_user
          else
            handle_merge_request_errors! merge_request.errors
          end
        end

        desc 'Update approvers and approver groups' do
          detail 'This feature was introduced in 10.6'
          success Entities::MergeRequestApprovals
        end
        params do
          requires :approver_ids, type: Array[String], allow_blank: true, desc: 'Array of User IDs to set as approvers.'
          requires :approver_group_ids, type: Array[String], allow_blank: true, desc: 'Array of Group IDs to set as approvers.'
        end
        put 'approvers' do
          merge_request = find_merge_request_with_access(params[:merge_request_iid], :update_approvers)

          merge_request = ::MergeRequests::UpdateService.new(user_project, current_user, declared(params, include_parent_namespaces: false).merge(remove_old_approvers: true)).execute(merge_request)

          if merge_request.valid?
            present merge_request, with: Entities::MergeRequestApprovals, current_user: current_user
          else
            handle_merge_request_errors! merge_request.errors
          end
        end

        # Approve a merge request
        #
        # Parameters:
        #   id (required)                 - The ID of a project
        #   merge_request_iid (required)  - IID of MR
        # Examples:
        #   POST /projects/:id/merge_requests/:merge_request_iid/approve
        #
        desc 'Approve a merge request' do
          success Entities::MergeRequestApprovals
        end
        params do
          optional :sha, type: String, desc: 'When present, must have the HEAD SHA of the source branch'
        end
        post 'approve' do
          merge_request = find_project_merge_request(params[:merge_request_iid])

          unauthorized! unless merge_request.can_approve?(current_user)

          check_sha_param!(params, merge_request)

          ::MergeRequests::ApprovalService
            .new(user_project, current_user)
            .execute(merge_request)

          present merge_request, with: Entities::MergeRequestApprovals, current_user: current_user
        end

        desc 'Remove an approval from a merge request' do
          success Entities::MergeRequestApprovals
        end
        post 'unapprove' do
          merge_request = find_project_merge_request(params[:merge_request_iid])

          not_found! unless merge_request.has_approved?(current_user)

          ::MergeRequests::RemoveApprovalService
            .new(user_project, current_user)
            .execute(merge_request)

          present merge_request, with: Entities::MergeRequestApprovals, current_user: current_user
        end
      end
    end
  end
end
