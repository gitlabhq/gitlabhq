module Gitlab
  # Hooks API
  class SystemHooks < Grape::API
    before { authenticated_as_admin! }

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
        @hook.execute(data)
        data
      end

      # Delete a hook
      #
      # Example Request:
      #   DELETE /hooks/:id
      delete ":id" do
        @hook = SystemHook.find(params[:id])
        @hook.destroy
      end
    end
  end
end