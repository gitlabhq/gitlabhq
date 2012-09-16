module Gitlab
  # Keys API
  class Keys < Grape::API
    before { authenticate! }
    resource :keys do
      # Get currently authenticated user's keys
      #
      # Example Request:
      #   GET /keys
      get do
        present current_user.keys, with: Entities::Key
      end
      # Add new ssh key to currently authenticated user
      # 
      # Parameters:
      #   key (required) - New SSH Key
      #   title (required) - New SSH Key's title
      # Example Request:
      #   POST /keys
      post do
        key = current_user.keys.new(
          title: params[:title],
          key: params[:key]
        )
        if key.save
          present key, with: Entities::Key
        else
          not_found!
        end
      end
      # Delete existed ssh key of currently authenticated user
      # 
      # Parameters:
      #   id (required) - SSH Key ID
      # Example Request:
      #   DELETE /keys/:id
      delete "/:id" do
        key = current_user.keys.find params[:id]
        key.delete
      end
    end
  end
end

