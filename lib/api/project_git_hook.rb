module API
  # Projects git hook API
  class ProjectGitHook < Grape::API
    before { authenticate! }
    before { authorize_admin_project }

    resource :projects do
      # Get project git hook
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/git_hook
      get ":id/git_hook" do
        @git_hooks = user_project.git_hook
        present @git_hooks, with: Entities::ProjectGitHook
      end

      # Add git hook to project
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   POST /projects/:id/git_hook
      post ":id/git_hook" do
        attrs = attributes_for_keys [
          :commit_message_regex,
          :deny_delete_tag
        ]

        if user_project.git_hook
          error!("Project git hook exists", 422)
        else
          @git_hook = user_project.create_git_hook(attrs)
          present @git_hook, with: Entities::ProjectGitHook
        end
      end

      # Update an existing project git hook
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   PUT /projects/:id/git_hook
      put ":id/git_hook" do
        @git_hook = user_project.git_hook

        attrs = attributes_for_keys [
          :commit_message_regex,
          :deny_delete_tag
        ]

        if @git_hook && @git_hook.update_attributes(attrs)
          present @git_hook, with: Entities::ProjectGitHook
        else
          not_found!
        end
      end

      # Deletes project git hook. This is an idempotent function.
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   DELETE /projects/:id/git_hook
      delete ":id/git_hook" do
        @git_hook = user_project.git_hook
        if @git_hook
          @git_hook.destroy
        else
          not_found!
        end
      end
    end
  end
end
