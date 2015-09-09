module API
  # Keys API
  class Keys < Grape::API
    before { authenticate! }

    resource :keys do
      # Get single ssh key by id. Only available to admin users.
      #
      # Example Request:
      #   GET /keys/:id
      get ":id" do
        authenticated_as_admin!

        key = Key.find(params[:id])

        present key, with: Entities::SSHKeyWithUser
      end
    end
  end
end
