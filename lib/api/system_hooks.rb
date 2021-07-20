# frozen_string_literal: true

module API
  class SystemHooks < ::API::Base
    include PaginationParams

    feature_category :integrations

    before do
      authenticate!
      authenticated_as_admin!
    end

    resource :hooks do
      desc 'Get the list of system hooks' do
        success Entities::Hook
      end
      params do
        use :pagination
      end
      get do
        present paginate(SystemHook.all), with: Entities::Hook
      end

      desc 'Create a new system hook' do
        success Entities::Hook
      end
      params do
        requires :url, type: String, desc: "The URL to send the request to"
        optional :token, type: String, desc: 'The token used to validate payloads'
        optional :push_events, type: Boolean, desc: "Trigger hook on push events"
        optional :tag_push_events, type: Boolean, desc: "Trigger hook on tag push events"
        optional :merge_requests_events, type: Boolean, desc: "Trigger hook on tag push events"
        optional :repository_update_events, type: Boolean, desc: "Trigger hook on repository update events"
        optional :enable_ssl_verification, type: Boolean, desc: "Do SSL verification when triggering the hook"
      end
      post do
        hook = SystemHook.new(declared_params(include_missing: false))

        if hook.save
          present hook, with: Entities::Hook
        else
          render_validation_error!(hook)
        end
      end

      desc 'Test a hook'
      params do
        requires :id, type: Integer, desc: 'The ID of the system hook'
      end
      post ":id" do
        hook = SystemHook.find(params[:id])
        data = {
          event_name: "project_create",
          name: "Ruby",
          path: "ruby",
          project_id: 1,
          owner_name: "Someone",
          owner_email: "example@gitlabhq.com"
        }
        hook.execute(data, 'system_hooks')
        data
      end

      desc 'Delete a hook' do
        success Entities::Hook
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the system hook'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id" do
        hook = SystemHook.find_by(id: params[:id])
        not_found!('System hook') unless hook

        destroy_conditionally!(hook) do
          WebHooks::DestroyService.new(current_user).execute(hook)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
