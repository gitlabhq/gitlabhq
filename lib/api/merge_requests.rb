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
        merge_requests = user_project.merge_requests

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
        present paginate(merge_requests), with: Entities::MergeRequest
      end

      # Show MR
      #
      # Parameters:
      #   id (required)               - The ID of a project
      #   merge_request_id (required) - The ID of MR
      #
      # Example:
      #   GET /projects/:id/merge_request/:merge_request_id
      #
      get ":id/merge_request/:merge_request_id" do
        merge_request = user_project.merge_requests.find(params[:merge_request_id])

        authorize! :read_merge_request, merge_request

        present merge_request, with: Entities::MergeRequest
      end

      # Show MR changes
      #
      # Parameters:
      #   id (required)               - The ID of a project
      #   merge_request_id (required) - The ID of MR
      #
      # Example:
      #   GET /projects/:id/merge_request/:merge_request_id/changes
      #
      get ':id/merge_request/:merge_request_id/changes' do
        merge_request = user_project.merge_requests.
          find(params[:merge_request_id])
        authorize! :read_merge_request, merge_request
        present merge_request, with: Entities::MergeRequestChanges
      end

      # Create MR
      #
      # Parameters:
      #
      #   id (required)            - The ID of a project - this will be the source of the merge request
      #   source_branch (required) - The source branch
      #   target_branch (required) - The target branch
      #   target_project           - The target project of the merge request defaults to the :id of the project
      #   assignee_id              - Assignee user ID
      #   title (required)         - Title of MR
      #   description              - Description of MR
      #   labels (optional)        - Labels for MR as a comma-separated list
      #
      # Example:
      #   POST /projects/:id/merge_requests
      #
      post ":id/merge_requests" do
        authorize! :create_merge_request, user_project
        required_attributes! [:source_branch, :target_branch, :title]
        attrs = attributes_for_keys [:source_branch, :target_branch, :assignee_id, :title, :target_project_id, :description]

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

          present merge_request, with: Entities::MergeRequest
        else
          handle_merge_request_errors! merge_request.errors
        end
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
      # Example:
      #   PUT /projects/:id/merge_request/:merge_request_id
      #
      put ":id/merge_request/:merge_request_id" do
        attrs = attributes_for_keys [:target_branch, :assignee_id, :title, :state_event, :description]
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

          present merge_request, with: Entities::MergeRequest
        else
          handle_merge_request_errors! merge_request.errors
        end
      end

      # Merge MR
      #
      # Parameters:
      #   id (required)                   - The ID of a project
      #   merge_request_id (required)     - ID of MR
      #   merge_commit_message (optional) - Custom merge commit message
      # Example:
      #   PUT /projects/:id/merge_request/:merge_request_id/merge
      #
      put ":id/merge_request/:merge_request_id/merge" do
        merge_request = user_project.merge_requests.find(params[:merge_request_id])

        allowed = ::Gitlab::GitAccess.new(current_user, user_project).
          can_push_to_branch?(merge_request.target_branch)

        if allowed
          if merge_request.unchecked?
            merge_request.check_if_can_be_merged
          end

          if merge_request.open? && !merge_request.work_in_progress?
            if merge_request.can_be_merged?
              commit_message = params[:merge_commit_message] || merge_request.merge_commit_message

              ::MergeRequests::MergeService.new(merge_request.target_project, current_user).
                execute(merge_request, commit_message)

              present merge_request, with: Entities::MergeRequest
            else
              render_api_error!('Branch cannot be merged', 405)
            end
          else
            # Merge request can not be merged
            # because it is already closed/merged or marked as WIP
            not_allowed!
          end
        else
          # Merge request can not be merged
          # because user dont have permissions to push into target branch
          unauthorized!
        end
      end


      # Get a merge request's comments
      #
      # Parameters:
      #   id (required)               - The ID of a project
      #   merge_request_id (required) - ID of MR
      # Examples:
      #   GET /projects/:id/merge_request/:merge_request_id/comments
      #
      get ":id/merge_request/:merge_request_id/comments" do
        merge_request = user_project.merge_requests.find(params[:merge_request_id])

        authorize! :read_merge_request, merge_request

        present paginate(merge_request.notes.fresh), with: Entities::MRNote
      end

      # Post comment to merge request
      #
      # Parameters:
      #   id (required)               - The ID of a project
      #   merge_request_id (required) - ID of MR
      #   note (required)             - Text of comment
      # Examples:
      #   POST /projects/:id/merge_request/:merge_request_id/comments
      #
      post ":id/merge_request/:merge_request_id/comments" do
        required_attributes! [:note]

        merge_request = user_project.merge_requests.find(params[:merge_request_id])
        note = merge_request.notes.new(note: params[:note], project_id: user_project.id)
        note.author = current_user

        if note.save
          present note, with: Entities::MRNote
        else
          render_api_error!("Failed to save note #{note.errors.messages}", 400)
        end
      end
    end
  end
end
