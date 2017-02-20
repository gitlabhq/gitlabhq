module API
  module V3
    class BroadcastMessages < Grape::API
      include PaginationParams

      before { authenticate! }
      before { authenticated_as_admin! }

      resource :broadcast_messages do
        helpers do
          def find_message
            BroadcastMessage.find(params[:id])
          end
        end

        desc 'Delete a broadcast message' do
          detail 'This feature was introduced in GitLab 8.12.'
          success ::API::Entities::BroadcastMessage
        end
        params do
          requires :id, type: Integer, desc: 'Broadcast message ID'
        end
        delete ':id' do
          message = find_message

          present message.destroy, with: ::API::Entities::BroadcastMessage
        end
      end
    end
  end
end
