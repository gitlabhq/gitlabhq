module API
  # MergeRequest API
  class MergeRequests < Grape::API
    before { authenticate! }

    resource :projects do
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
          end

          render_api_error!(errors, 400)
        end
      end

      # List merge requests
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   iid (optional) - Return the project MR having the given `iid`
      #   state (optional) - Return requests "merged", "opened" or "closed"
      #   order_by (optional) - Return requests ordered by `created_at` or `updated_at` fields. Default is `created_at`
      #   sort (optional) - Return requests sorted in `asc` or `desc` order. Default is `desc`
      #
      # Example:
      #   GET /projects/:id/merge_requests
      #   GET /projects/:id/merge_requests?state=opened
      #   GET /projects/:id/merge_requests?state=closed
      #   GET /projects/:id/merge_requests?order_by=created_at
      #   GET /projects/:id/merge_requests?order_by=updated_at
      #   GET /projects/:id/merge_requests?sort=desc
      #   GET /projects/:id/merge_requests?sort=asc
      #   GET /projects/:id/merge_requests?iid=42
      #
      get ":id/merge_requests" do
        authorize! :read_merge_request, user_project
        merge_requests = user_project.merge_requests.inc_notes_with_associations

        unless params[:iid].nil?
          merge_requests = filter_by_iid(merge_requests, params[:iid])
        end

        merge_requests =
          case params["state"]
          when "opened" then merge_requests.opened
          when "closed" then merge_requests.closed
          when "merged" then merge_requests.merged
          else merge_requests
          end

        merge_requests = merge_requests.reorder(issuable_order_by => issuable_sort)
        present paginate(merge_requests), with: Entities::MergeRequest, current_user: current_user
      end

      # Create MR
      #
      # Parameters:
      #
      #   id (required)                      - The ID of a project - this will be the source of the merge request
      #   source_branch (required)           - The source branch
      #   target_branch (required)           - The target branch
      #   target_project_id (optional)       - The target project of the merge request defaults to the :id of the project
      #   assignee_id (optional)             - Assignee user ID
      #   title (required)                   - Title of MR
      #   description (optional)             - Description of MR
      #   labels (optional)                  - Labels for MR as a comma-separated list
      #   milestone_id (optional)            - Milestone ID
      #   approvals_before_merge (optional)  - Number of approvals required before this can be merged
      #
      # Example:
      #   POST /projects/:id/merge_requests
      #
      post ":id/merge_requests" do
        authorize! :create_merge_request, user_project
        required_attributes! [:source_branch, :target_branch, :title]
        attrs = attributes_for_keys [:source_branch, :target_branch, :assignee_id, :title, :target_project_id, :description, :milestone_id, :approvals_before_merge]

        # Validate label names in advance
        if (errors = validate_label_params(params)).any?
          render_api_error!({ labels: errors }, 400)
        end

        merge_request = ::MergeRequests::CreateService.new(user_project, current_user, attrs).execute

        if merge_request.valid?
          # Find or create labels and attach to issue
          if params[:labels].present?
            merge_request.add_labels_by_names(params[:labels].split(","))
          end

          present merge_request, with: Entities::MergeRequest, current_user: current_user
        else
          handle_merge_request_errors! merge_request.errors
        end
      end

      # Delete a MR
      #
      # Parameters:
      # id (required)               - The ID of the project
      # merge_request_id (required) - The MR id
      delete ":id/merge_requests/:merge_request_id" do
        merge_request = user_project.merge_requests.find_by(id: params[:merge_request_id])

        authorize!(:destroy_merge_request, merge_request)
        merge_request.destroy
      end

      # Routing "merge_request/:merge_request_id/..." is DEPRECATED and WILL BE REMOVED in version 9.0
      # Use "merge_requests/:merge_request_id/..." instead.
      #
      [":id/merge_request/:merge_request_id", ":id/merge_requests/:merge_request_id"].each do |path|
        # Show MR
        #
        # Parameters:
        #   id (required)               - The ID of a project
        #   merge_request_id (required) - The ID of MR
        #
        # Example:
        #   GET /projects/:id/merge_requests/:merge_request_id
        #
        get path do
          merge_request = user_project.merge_requests.find(params[:merge_request_id])

          authorize! :read_merge_request, merge_request

          present merge_request, with: Entities::MergeRequest, current_user: current_user
        end

        # Show MR commits
        #
        # Parameters:
        #   id (required)               - The ID of a project
        #   merge_request_id (required) - The ID of MR
        #
        # Example:
        #   GET /projects/:id/merge_requests/:merge_request_id/commits
        #
        get "#{path}/commits" do
          merge_request = user_project.merge_requests.
            find(params[:merge_request_id])
          authorize! :read_merge_request, merge_request
          present merge_request.commits, with: Entities::RepoCommit
        end

        # Show MR changes
        #
        # Parameters:
        #   id (required)               - The ID of a project
        #   merge_request_id (required) - The ID of MR
        #
        # Example:
        #   GET /projects/:id/merge_requests/:merge_request_id/changes
        #
        get "#{path}/changes" do
          merge_request = user_project.merge_requests.
            find(params[:merge_request_id])
          authorize! :read_merge_request, merge_request
          present merge_request, with: Entities::MergeRequestChanges, current_user: current_user
        end

        # Update MR
        #
        # Parameters:
        #   id (required)               - The ID of a project
        #   merge_request_id (required) - ID of MR
        #   target_branch               - The target branch
        #   assignee_id                 - Assignee user ID
        #   title                       - Title of MR
        #   state_event                 - Status of MR. (close|reopen|merge)
        #   description                 - Description of MR
        #   labels (optional)           - Labels for a MR as a comma-separated list
        #   milestone_id (optional)     - Milestone ID
        # Example:
        #   PUT /projects/:id/merge_requests/:merge_request_id
        #
        put path do
          attrs = attributes_for_keys [:target_branch, :assignee_id, :title, :state_event, :description, :milestone_id]
          merge_request = user_project.merge_requests.find(params[:merge_request_id])
          authorize! :update_merge_request, merge_request

          # Ensure source_branch is not specified
          if params[:source_branch].present?
            render_api_error!('Source branch cannot be changed', 400)
          end

          # Validate label names in advance
          if (errors = validate_label_params(params)).any?
            render_api_error!({ labels: errors }, 400)
          end

          merge_request = ::MergeRequests::UpdateService.new(user_project, current_user, attrs).execute(merge_request)

          if merge_request.valid?
            # Find or create labels and attach to issue
            unless params[:labels].nil?
              merge_request.remove_labels
              merge_request.add_labels_by_names(params[:labels].split(","))
            end

            present merge_request, with: Entities::MergeRequest, current_user: current_user
          else
            handle_merge_request_errors! merge_request.errors
          end
        end

        # Merge MR
        #
        # Parameters:
        #   id (required)                           - The ID of a project
        #   merge_request_id (required)             - ID of MR
        #   merge_commit_message (optional)         - Custom merge commit message
        #   should_remove_source_branch (optional)  - When true, the source branch will be deleted if possible
        #   merge_when_build_succeeds (optional)    - When true, this MR will be merged when the build succeeds
        #   sha (optional)                          - When present, must have the HEAD SHA of the source branch
        # Example:
        #   PUT /projects/:id/merge_requests/:merge_request_id/merge
        #
        put "#{path}/merge" do
          merge_request = user_project.merge_requests.find(params[:merge_request_id])

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

          if parse_boolean(params[:merge_when_build_succeeds]) && merge_request.pipeline && merge_request.pipeline.active?
            ::MergeRequests::MergeWhenBuildSucceedsService.new(merge_request.target_project, current_user, merge_params).
              execute(merge_request)
          else
            ::MergeRequests::MergeService.new(merge_request.target_project, current_user, merge_params).
              execute(merge_request)
          end

          present merge_request, with: Entities::MergeRequest, current_user: current_user
        end

        # Cancel Merge if Merge When build succeeds is enabled
        # Parameters:
        #   id (required)                         - The ID of a project
        #   merge_request_id (required)           - ID of MR
        #
        post "#{path}/cancel_merge_when_build_succeeds" do
          merge_request = user_project.merge_requests.find(params[:merge_request_id])

          unauthorized! unless merge_request.can_cancel_merge_when_build_succeeds?(current_user)

          ::MergeRequest::MergeWhenBuildSucceedsService.new(merge_request.target_project, current_user).cancel(merge_request)
        end

        # Duplicate. DEPRECATED and WILL BE REMOVED in 9.0.
        # Use GET "/projects/:id/merge_requests/:merge_request_id/notes" instead
        #
        # Get a merge request's comments
        #
        # Parameters:
        #   id (required)               - The ID of a project
        #   merge_request_id (required) - ID of MR
        # Examples:
        #   GET /projects/:id/merge_requests/:merge_request_id/comments
        #
        get "#{path}/comments" do
          merge_request = user_project.merge_requests.find(params[:merge_request_id])

          authorize! :read_merge_request, merge_request

          present paginate(merge_request.notes.fresh), with: Entities::MRNote
        end

        # Duplicate. DEPRECATED and WILL BE REMOVED in 9.0.
        # Use POST "/projects/:id/merge_requests/:merge_request_id/notes" instead
        #
        # Post comment to merge request
        #
        # Parameters:
        #   id (required)               - The ID of a project
        #   merge_request_id (required) - ID of MR
        #   note (required)             - Text of comment
        # Examples:
        #   POST /projects/:id/merge_requests/:merge_request_id/comments
        #
        post "#{path}/comments" do
          required_attributes! [:note]

          merge_request = user_project.merge_requests.find(params[:merge_request_id])

          authorize! :create_note, merge_request

          opts = {
            note: params[:note],
            noteable_type: 'MergeRequest',
            noteable_id: merge_request.id
          }

          note = ::Notes::CreateService.new(user_project, current_user, opts).execute

          if note.save
            present note, with: Entities::MRNote
          else
            render_api_error!("Failed to save note #{note.errors.messages}", 400)
          end
        end

        # List issues that will close on merge
        #
        # Parameters:
        #   id (required)               - The ID of a project
        #   merge_request_id (required) - ID of MR
        # Examples:
        #   GET /projects/:id/merge_requests/:merge_request_id/closes_issues
        get "#{path}/closes_issues" do
          merge_request = user_project.merge_requests.find(params[:merge_request_id])
          issues = ::Kaminari.paginate_array(merge_request.closes_issues(current_user))
          present paginate(issues), with: issue_entity(user_project), current_user: current_user
        end

        # Get the status of the merge request's approvals
        #
        # Parameters:
        #   id (required)                 - The ID of a project
        #   merge_request_id (required)   - ID of MR
        # Examples:
        #   GET /projects/:id/merge_requests/:merge_request_id/approvals
        #
        get "#{path}/approvals" do
          merge_request = user_project.merge_requests.find(params[:merge_request_id])

          authorize! :read_merge_request, merge_request
          present merge_request, with: Entities::MergeRequestApprovals, current_user: current_user
        end

        # Approve a merge request
        #
        # Parameters:
        #   id (required)                 - The ID of a project
        #   merge_request_id (required)   - ID of MR
        # Examples:
        #   POST /projects/:id/merge_requests/:merge_request_id/approvals
        #
        post "#{path}/approve" do
          merge_request = user_project.merge_requests.find(params[:merge_request_id])

          unauthorized! unless merge_request.can_approve?(current_user)

          ::MergeRequests::ApprovalService
            .new(user_project, current_user)
            .execute(merge_request)

          present merge_request, with: Entities::MergeRequestApprovals, current_user: current_user
        end
      end
    end
  end
end
