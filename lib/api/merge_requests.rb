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
          end
          not_found!
        end
      end

      # List merge requests
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   state (optional) - Return requests "merged", "opened" or "closed"
      #
      # Example:
      #   GET /projects/:id/merge_requests
      #   GET /projects/:id/merge_requests?state=opened
      #   GET /projects/:id/merge_requests?state=closed
      #
      get ":id/merge_requests" do
        authorize! :read_merge_request, user_project

        mrs = case params["state"]
              when "opened" then user_project.merge_requests.opened
              when "closed" then user_project.merge_requests.closed
              when "merged" then user_project.merge_requests.merged
              else user_project.merge_requests
              end

        present paginate(mrs), with: Entities::MergeRequest
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
        authorize! :write_merge_request, user_project
        required_attributes! [:source_branch, :target_branch, :title]
        attrs = attributes_for_keys [:source_branch, :target_branch, :assignee_id, :title, :target_project_id, :description]
        attrs[:label_list] = params[:labels] if params[:labels].present?
        merge_request = ::MergeRequests::CreateService.new(user_project, current_user, attrs).execute

        if merge_request.valid?
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
      #   source_branch               - The source branch
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
        attrs = attributes_for_keys [:source_branch, :target_branch, :assignee_id, :title, :state_event, :description]
        attrs[:label_list] = params[:labels] if params[:labels].present?
        merge_request = user_project.merge_requests.find(params[:merge_request_id])
        authorize! :modify_merge_request, merge_request
        merge_request = ::MergeRequests::UpdateService.new(user_project, current_user, attrs).execute(merge_request)

        if merge_request.valid?
          present merge_request, with: Entities::MergeRequest
        else
          handle_merge_request_errors! merge_request.errors
        end
      end

      # Merge MR
      #
      # Parameters:
      #   id (required)               - The ID of a project
      #   merge_request_id (required) - ID of MR
      #   merge_commit_message (optional) - Custom merge commit message
      # Example:
      #   PUT /projects/:id/merge_request/:merge_request_id/merge
      #
      put ":id/merge_request/:merge_request_id/merge" do
        merge_request = user_project.merge_requests.find(params[:merge_request_id])

        action = if user_project.protected_branch?(merge_request.target_branch)
                   :push_code_to_protected_branches
                 else
                   :push_code
                 end

        if can?(current_user, action, user_project)
          if merge_request.unchecked?
            merge_request.check_if_can_be_merged
          end

          if merge_request.open?
            if merge_request.can_be_merged?
              merge_request.automerge!(current_user, params[:merge_commit_message] || merge_request.merge_commit_message)
              present merge_request, with: Entities::MergeRequest
            else
              render_api_error!('Branch cannot be merged', 405)
            end
          else
            # Merge request can not be merged
            # because it is already closed/merged
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
      #   id (required) - The ID of a project
      #   merge_request_id (required) - ID of MR
      # Examples:
      #   GET /projects/:id/merge_request/:merge_request_id/comments
      #
      get ":id/merge_request/:merge_request_id/comments" do
        merge_request = user_project.merge_requests.find(params[:merge_request_id])

        authorize! :read_merge_request, merge_request

        present paginate(merge_request.notes), with: Entities::MRNote
      end

      # Post comment to merge request
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   merge_request_id (required) - ID of MR
      #   note (required) - Text of comment
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
          not_found!
        end
      end
    end
  end
end
