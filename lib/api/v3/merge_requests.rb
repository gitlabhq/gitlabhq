module API
  module V3
    class MergeRequests < Grape::API
      include PaginationParams

      DEPRECATION_MESSAGE = 'This endpoint is deprecated and has been removed on V4'.freeze

      before { authenticate! }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: { id: %r{[^/]+} } do
        include TimeTrackingEndpoints

        helpers do
          def handle_merge_request_errors!(errors)
            if errors[:project_access].any?
              error!(errors[:project_access], 422)
            elsif errors[:branch_conflict].any?
              error!(errors[:branch_conflict], 422)
            elsif errors[:validate_fork].any?
              error!(errors[:validate_fork], 422)
            elsif errors[:validate_branches].any?
              conflict!(errors[:validate_branches])
            elsif errors[:base].any?
              error!(errors[:base], 422)
            end

            render_api_error!(errors, 400)
          end

          def issue_entity(project)
            if project.has_external_issue_tracker?
              ::API::Entities::ExternalIssue
            else
              ::API::V3::Entities::Issue
            end
          end

          params :optional_params do
            optional :description, type: String, desc: 'The description of the merge request'
            optional :assignee_id, type: Integer, desc: 'The ID of a user to assign the merge request'
            optional :milestone_id, type: Integer, desc: 'The ID of a milestone to assign the merge request'
            optional :labels, type: String, desc: 'Comma-separated list of label names'
            optional :remove_source_branch, type: Boolean, desc: 'Remove source branch when merging'
          end
        end

        desc 'List merge requests' do
          detail 'iid filter is deprecated have been removed on V4'
          success ::API::V3::Entities::MergeRequest
        end
        params do
          optional :state, type: String, values: %w[opened closed merged all], default: 'all',
                           desc: 'Return opened, closed, merged, or all merge requests'
          optional :order_by, type: String, values: %w[created_at updated_at], default: 'created_at',
                              desc: 'Return merge requests ordered by `created_at` or `updated_at` fields.'
          optional :sort, type: String, values: %w[asc desc], default: 'desc',
                          desc: 'Return merge requests sorted in `asc` or `desc` order.'
          optional :iid, type: Array[Integer], desc: 'The IID of the merge requests'
          use :pagination
        end
        get ":id/merge_requests" do
          authorize! :read_merge_request, user_project

          merge_requests = user_project.merge_requests.inc_notes_with_associations
          merge_requests = filter_by_iid(merge_requests, params[:iid]) if params[:iid].present?

          merge_requests =
            case params[:state]
            when 'opened' then merge_requests.opened
            when 'closed' then merge_requests.closed
            when 'merged' then merge_requests.merged
            else merge_requests
            end

          merge_requests = merge_requests.reorder(params[:order_by] => params[:sort])
          present paginate(merge_requests), with: ::API::V3::Entities::MergeRequest, current_user: current_user, project: user_project
        end

        desc 'Create a merge request' do
          success ::API::V3::Entities::MergeRequest
        end
        params do
          requires :title, type: String, desc: 'The title of the merge request'
          requires :source_branch, type: String, desc: 'The source branch'
          requires :target_branch, type: String, desc: 'The target branch'
          optional :target_project_id, type: Integer,
                                       desc: 'The target project of the merge request defaults to the :id of the project'
          use :optional_params
        end
        post ":id/merge_requests" do
          Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42126')

          authorize! :create_merge_request_from, user_project

          mr_params = declared_params(include_missing: false)
          mr_params[:force_remove_source_branch] = mr_params.delete(:remove_source_branch) if mr_params[:remove_source_branch].present?

          merge_request = ::MergeRequests::CreateService.new(user_project, current_user, mr_params).execute

          if merge_request.valid?
            present merge_request, with: ::API::V3::Entities::MergeRequest, current_user: current_user, project: user_project
          else
            handle_merge_request_errors! merge_request.errors
          end
        end

        desc 'Delete a merge request'
        params do
          requires :merge_request_id, type: Integer, desc: 'The ID of a merge request'
        end
        delete ":id/merge_requests/:merge_request_id" do
          merge_request = find_project_merge_request(params[:merge_request_id])

          authorize!(:destroy_merge_request, merge_request)

          status(200)
          merge_request.destroy
        end

        params do
          requires :merge_request_id, type: Integer, desc: 'The ID of a merge request'
        end
        { ":id/merge_request/:merge_request_id" => :deprecated, ":id/merge_requests/:merge_request_id" => :ok }.each do |path, status|
          desc 'Get a single merge request' do
            if status == :deprecated
              detail DEPRECATION_MESSAGE
            end

            success ::API::V3::Entities::MergeRequest
          end
          get path do
            merge_request = find_merge_request_with_access(params[:merge_request_id])

            present merge_request, with: ::API::V3::Entities::MergeRequest, current_user: current_user, project: user_project
          end

          desc 'Get the commits of a merge request' do
            success ::API::Entities::Commit
          end
          get "#{path}/commits" do
            merge_request = find_merge_request_with_access(params[:merge_request_id])

            present merge_request.commits, with: ::API::Entities::Commit
          end

          desc 'Show the merge request changes' do
            success ::API::Entities::MergeRequestChanges
          end
          get "#{path}/changes" do
            merge_request = find_merge_request_with_access(params[:merge_request_id])

            present merge_request, with: ::API::Entities::MergeRequestChanges, current_user: current_user
          end

          desc 'Update a merge request' do
            success ::API::V3::Entities::MergeRequest
          end
          params do
            optional :title, type: String, allow_blank: false, desc: 'The title of the merge request'
            optional :target_branch, type: String, allow_blank: false, desc: 'The target branch'
            optional :state_event, type: String, values: %w[close reopen merge],
                                   desc: 'Status of the merge request'
            use :optional_params
            at_least_one_of :title, :target_branch, :description, :assignee_id,
                            :milestone_id, :labels, :state_event,
                            :remove_source_branch
          end
          put path do
            Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42127')

            merge_request = find_merge_request_with_access(params.delete(:merge_request_id), :update_merge_request)

            mr_params = declared_params(include_missing: false)
            mr_params[:force_remove_source_branch] = mr_params.delete(:remove_source_branch) if mr_params[:remove_source_branch].present?

            merge_request = ::MergeRequests::UpdateService.new(user_project, current_user, mr_params).execute(merge_request)

            if merge_request.valid?
              present merge_request, with: ::API::V3::Entities::MergeRequest, current_user: current_user, project: user_project
            else
              handle_merge_request_errors! merge_request.errors
            end
          end

          desc 'Merge a merge request' do
            success ::API::V3::Entities::MergeRequest
          end
          params do
            optional :merge_commit_message, type: String, desc: 'Custom merge commit message'
            optional :should_remove_source_branch, type: Boolean,
                                                   desc: 'When true, the source branch will be deleted if possible'
            optional :merge_when_build_succeeds, type: Boolean,
                                                 desc: 'When true, this merge request will be merged when the build succeeds'
            optional :sha, type: String, desc: 'When present, must have the HEAD SHA of the source branch'
          end
          put "#{path}/merge" do
            merge_request = find_project_merge_request(params[:merge_request_id])

            # Merge request can not be merged
            # because user dont have permissions to push into target branch
            unauthorized! unless merge_request.can_be_merged_by?(current_user)

            not_allowed! unless merge_request.mergeable_state?

            render_api_error!('Branch cannot be merged', 406) unless merge_request.mergeable?

            if params[:sha] && merge_request.diff_head_sha != params[:sha]
              render_api_error!("SHA does not match HEAD of source branch: #{merge_request.diff_head_sha}", 409)
            end

            merge_params = {
              commit_message: params[:merge_commit_message],
              should_remove_source_branch: params[:should_remove_source_branch]
            }

            if params[:merge_when_build_succeeds] && merge_request.head_pipeline && merge_request.head_pipeline.active?
              ::MergeRequests::MergeWhenPipelineSucceedsService
                .new(merge_request.target_project, current_user, merge_params)
                .execute(merge_request)
            else
              ::MergeRequests::MergeService
                .new(merge_request.target_project, current_user, merge_params)
                .execute(merge_request)
            end

            present merge_request, with: ::API::V3::Entities::MergeRequest, current_user: current_user, project: user_project
          end

          desc 'Cancel merge if "Merge When Build succeeds" is enabled' do
            success ::API::V3::Entities::MergeRequest
          end
          post "#{path}/cancel_merge_when_build_succeeds" do
            merge_request = find_project_merge_request(params[:merge_request_id])

            unauthorized! unless merge_request.can_cancel_merge_when_pipeline_succeeds?(current_user)

            ::MergeRequest::MergeWhenPipelineSucceedsService
              .new(merge_request.target_project, current_user)
              .cancel(merge_request)
          end

          desc 'Get the comments of a merge request' do
            detail 'Duplicate. DEPRECATED and HAS BEEN REMOVED in V4'
            success ::API::Entities::MRNote
          end
          params do
            use :pagination
          end
          get "#{path}/comments" do
            merge_request = find_merge_request_with_access(params[:merge_request_id])
            present paginate(merge_request.notes.fresh), with: ::API::Entities::MRNote
          end

          desc 'Post a comment to a merge request' do
            detail 'Duplicate. DEPRECATED and HAS BEEN REMOVED in V4'
            success ::API::Entities::MRNote
          end
          params do
            requires :note, type: String, desc: 'The text of the comment'
          end
          post "#{path}/comments" do
            merge_request = find_merge_request_with_access(params[:merge_request_id], :create_note)

            opts = {
              note: params[:note],
              noteable_type: 'MergeRequest',
              noteable_id: merge_request.id
            }

            note = ::Notes::CreateService.new(user_project, current_user, opts).execute

            if note.save
              present note, with: ::API::Entities::MRNote
            else
              render_api_error!("Failed to save note #{note.errors.messages}", 400)
            end
          end

          desc 'List issues that will be closed on merge' do
            success ::API::Entities::MRNote
          end
          params do
            use :pagination
          end
          get "#{path}/closes_issues" do
            merge_request = find_merge_request_with_access(params[:merge_request_id])
            issues = ::Kaminari.paginate_array(merge_request.closes_issues(current_user))
            present paginate(issues), with: issue_entity(user_project), current_user: current_user
          end
        end
      end
    end
  end
end
