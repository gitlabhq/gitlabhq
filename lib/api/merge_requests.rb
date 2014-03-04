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

        def not_fork?(target_project_id, user_project)
          target_project_id.nil? || target_project_id == user_project.id.to_s
        end

        def target_matches_fork(target_project_id,user_project)
          user_project.forked? && user_project.forked_from_project.id.to_s == target_project_id
        end
      end

      # List merge requests
      #
      # Parameters:
      #   id (required) - The ID of a project
      #
      # Example:
      #   GET /projects/:id/merge_requests
      #
      get ":id/merge_requests" do
        authorize! :read_merge_request, user_project

        present paginate(user_project.merge_requests), with: Entities::MergeRequest
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
      #
      # Example:
      #   POST /projects/:id/merge_requests
      #
      post ":id/merge_requests" do
        set_current_user_for_thread do
          authorize! :write_merge_request, user_project
          required_attributes! [:source_branch, :target_branch, :title]
          attrs = attributes_for_keys [:source_branch, :target_branch, :assignee_id, :title, :target_project_id]
          merge_request = user_project.merge_requests.new(attrs)
          merge_request.author = current_user
          merge_request.source_project = user_project
          target_project_id = attrs[:target_project_id]
          if not_fork?(target_project_id, user_project)
            merge_request.target_project = user_project
          else
            if target_matches_fork(target_project_id,user_project)
              merge_request.target_project = Project.find_by(id: attrs[:target_project_id])
            else
              render_api_error!('(Bad Request) Specified target project that is not the source project, or the source fork of the project.', 400)
            end
          end

          if merge_request.save
            present merge_request, with: Entities::MergeRequest
          else
            handle_merge_request_errors! merge_request.errors
          end
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
      # Example:
      #   PUT /projects/:id/merge_request/:merge_request_id
      #
      put ":id/merge_request/:merge_request_id" do
        set_current_user_for_thread do
          attrs = attributes_for_keys [:source_branch, :target_branch, :assignee_id, :title, :state_event]
          merge_request = user_project.merge_requests.find(params[:merge_request_id])

          authorize! :modify_merge_request, merge_request

          if merge_request.update_attributes attrs
            present merge_request, with: Entities::MergeRequest
          else
            handle_merge_request_errors! merge_request.errors
          end
        end
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
        set_current_user_for_thread do
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
end
