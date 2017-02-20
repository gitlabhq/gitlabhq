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
      end
    end
  end
end
