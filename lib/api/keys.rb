module API
  # Keys API
  class Keys < Grape::API
    before { authenticate! }

    resource :keys do
      desc 'Get single ssh key by id. Only available to admin users' do
        success Entities::SSHKeyWithUser
      end
      get ":id" do
        authenticated_as_admin!

        key = Key.find(params[:id])

        present key, with: Entities::SSHKeyWithUser, current_user: current_user
      end
    end
  end
end
