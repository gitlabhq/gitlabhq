module API
  # Hooks API
  class SystemHooks < Grape::API
    before do
      authenticate!
      authenticated_as_admin!
    end

    resource :hooks do
      # Get the list of system hooks
      #
      # Example Request:
      #   GET /hooks
      get do
        @hooks = SystemHook.all
        present @hooks, with: Entities::Hook
      end

      # Create new system hook
      #
      # Parameters:
      #   url (required) - url for system hook
      # Example Request
      #   POST /hooks
      post do
        attrs = attributes_for_keys [:url]
        required_attributes! [:url]
        @hook = SystemHook.new attrs
        if @hook.save
          present @hook, with: Entities::Hook
        else
          not_found!
        end
      end

      # Test a hook
      #
      # Example Request
      #   GET /hooks/:id
      get ":id" do
        @hook = SystemHook.find(params[:id])
        data = {
          event_name: "project_create",
          name: "Ruby",
          path: "ruby",
          project_id: 1,
          owner_name: "Someone",
          owner_email: "example@gitlabhq.com"
        }
        @hook.execute(data, 'system_hooks')
        data
      end

      # Delete a hook. This is an idempotent function.
      #
      # Parameters:
      #   id (required) - ID of the hook
      # Example Request:
      #   DELETE /hooks/:id
      delete ":id" do
        begin
          @hook = SystemHook.find(params[:id])
          @hook.destroy
        rescue
          # SystemHook raises an Error if no hook with id found
        end
      end
    end
  end
end
