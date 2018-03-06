module EE
  module API
    module MergeRequests
      extend ActiveSupport::Concern

      class_methods do
        def update_params_at_least_one_of
          super.push(*%i[
            squash
          ])
        end
      end

      prepended do
        helpers do
          params :merge_params_ee do
            optional :squash, type: Grape::API::Boolean, desc: 'When true, the commits will be squashed into a single commit on merge'
          end

          params :optional_params_ee do
            optional :approvals_before_merge, type: Integer, desc: 'Number of approvals required before this can be merged'
            use :merge_params_ee
          end

          def update_merge_request_ee(merge_request)
            if params[:squash] && merge_request.project.feature_available?(:merge_request_squash)
              merge_request.update(squash: params[:squash])
            end
          end
        end

        params do
          requires :id, type: String, desc: 'The ID of a project'
        end
        resource :projects, requirements: ::API::API::PROJECT_ENDPOINT_REQUIREMENTS do
          # Get the status of the merge request's approvals
          #
          # Parameters:
          #   id (required)                 - The ID of a project
          #   merge_request_idd (required)  - IID of MR
          # Examples:
          #   GET /projects/:id/merge_requests/:merge_request_iid/approvals
          #
          desc "List a merge request's approvals" do
            success EE::API::Entities::MergeRequestApprovals
          end
          get ':id/merge_requests/:merge_request_iid/approvals' do
            merge_request = find_merge_request_with_access(params[:merge_request_iid])

            present merge_request, with: EE::API::Entities::MergeRequestApprovals, current_user: current_user
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
            success EE::API::Entities::MergeRequestApprovals
          end
          params do
            optional :sha, type: String, desc: 'When present, must have the HEAD SHA of the source branch'
          end
          post ':id/merge_requests/:merge_request_iid/approve' do
            merge_request = find_project_merge_request(params[:merge_request_iid])

            unauthorized! unless merge_request.can_approve?(current_user)

            check_sha_param!(params, merge_request)

            ::MergeRequests::ApprovalService
              .new(user_project, current_user)
              .execute(merge_request)

            present merge_request, with: EE::API::Entities::MergeRequestApprovals, current_user: current_user
          end

          desc 'Remove an approval from a merge request' do
            success EE::API::Entities::MergeRequestApprovals
          end
          post ':id/merge_requests/:merge_request_iid/unapprove' do
            merge_request = find_project_merge_request(params[:merge_request_iid])

            not_found! unless merge_request.has_approved?(current_user)

            ::MergeRequests::RemoveApprovalService
              .new(user_project, current_user)
              .execute(merge_request)

            present merge_request, with: EE::API::Entities::MergeRequestApprovals, current_user: current_user
          end
        end
      end
    end
  end
end
