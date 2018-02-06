module API
  module V3
    class SystemHooks < Grape::API
      before do
        authenticate!
        authenticated_as_admin!
      end

      resource :hooks do
        desc 'Get the list of system hooks' do
          success ::API::Entities::Hook
        end
        get do
          present SystemHook.all, with: ::API::Entities::Hook
        end

        desc 'Delete a hook' do
          success ::API::Entities::Hook
        end
        params do
          requires :id, type: Integer, desc: 'The ID of the system hook'
        end
        delete ":id" do
          hook = SystemHook.find_by(id: params[:id])
          not_found!('System hook') unless hook

          present hook.destroy, with: ::API::Entities::Hook
        end
      end
    end
  end
end
