module API
  # Projects API
  class ProjectHooks < Grape::API
    before { authenticate! }
    before { authorize_admin_project }

    resource :projects do
      # Get project hooks
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/hooks
      get ":id/hooks" do
        @hooks = paginate user_project.hooks
        present @hooks, with: Entities::ProjectHook
      end

      # Get a project hook
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   hook_id (required) - The ID of a project hook
      # Example Request:
      #   GET /projects/:id/hooks/:hook_id
      get ":id/hooks/:hook_id" do
        @hook = user_project.hooks.find(params[:hook_id])
        present @hook, with: Entities::ProjectHook
      end

      # Add hook to project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   url (required) - The hook URL
      # Example Request:
      #   POST /projects/:id/hooks
      post ":id/hooks" do
        required_attributes! [:url]
        attrs = attributes_for_keys [
          :url,
          :push_events,
          :issues_events,
          :merge_requests_events,
          :tag_push_events,
          :note_events,
          :pipeline_events,
          :wiki_page_events,
          :enable_ssl_verification
        ]
        @hook = user_project.hooks.new(attrs)

        if @hook.save
          present @hook, with: Entities::ProjectHook
        else
          if @hook.errors[:url].present?
            error!("Invalid url given", 422)
          end
          not_found!("Project hook #{@hook.errors.messages}")
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
        required_attributes! [:url]
        attrs = attributes_for_keys [
          :url,
          :push_events,
          :issues_events,
          :merge_requests_events,
          :tag_push_events,
          :note_events,
          :pipeline_events,
          :wiki_page_events,
          :enable_ssl_verification
        ]

        if @hook.update_attributes attrs
          present @hook, with: Entities::ProjectHook
        else
          if @hook.errors[:url].present?
            error!("Invalid url given", 422)
          end
          not_found!("Project hook #{@hook.errors.messages}")
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
        required_attributes! [:hook_id]

        begin
          @hook = user_project.hooks.destroy(params[:hook_id])
        rescue
          # ProjectHook can raise Error if hook_id not found
          not_found!("Error deleting hook #{params[:hook_id]}")
        end
      end
    end
  end
end
