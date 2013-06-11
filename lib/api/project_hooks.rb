module API
  # Projects API
  class ProjectHooks < Grape::API
    before { authenticate! }

    resource :projects do
      helpers do
        def handle_project_member_errors(errors)
          if errors[:project_access].any?
            error!(errors[:project_access], 422)
          end
          not_found!
        end
      end

      # Get project hooks
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/hooks
      get ":id/hooks" do
        authorize! :admin_project, user_project
        @hooks = paginate user_project.hooks
        present @hooks, with: Entities::Hook
      end

      # Get a project hook
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   hook_id (required) - The ID of a project hook
      # Example Request:
      #   GET /projects/:id/hooks/:hook_id
      get ":id/hooks/:hook_id" do
        authorize! :admin_project, user_project
        @hook = user_project.hooks.find(params[:hook_id])
        present @hook, with: Entities::Hook
      end


      # Add hook to project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   url (required) - The hook URL
      # Example Request:
      #   POST /projects/:id/hooks
      post ":id/hooks" do
        authorize! :admin_project, user_project
        required_attributes! [:url]

        @hook = user_project.hooks.new({"url" => params[:url]})
        if @hook.save
          present @hook, with: Entities::Hook
        else
          if @hook.errors[:url].present?
            error!("Invalid url given", 422)
          end
          not_found!
        end
      end

      # Update an existing project hook
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   hook_id (required) - The ID of a project hook
      #   url (required) - The hook URL
      # Example Request:
      #   PUT /projects/:id/hooks/:hook_id
      put ":id/hooks/:hook_id" do
        @hook = user_project.hooks.find(params[:hook_id])
        authorize! :admin_project, user_project
        required_attributes! [:url]

        attrs = attributes_for_keys [:url]
        if @hook.update_attributes attrs
          present @hook, with: Entities::Hook
        else
          if @hook.errors[:url].present?
            error!("Invalid url given", 422)
          end
          not_found!
        end
      end

      # Deletes project hook. This is an idempotent function.
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   hook_id (required) - The ID of hook to delete
      # Example Request:
      #   DELETE /projects/:id/hooks/:hook_id
      delete ":id/hooks/:hook_id" do
        authorize! :admin_project, user_project
        required_attributes! [:hook_id]

        begin
          @hook = ProjectHook.find(params[:hook_id])
          @hook.destroy
        rescue
          # ProjectHook can raise Error if hook_id not found
        end
      end
    end
  end
end
