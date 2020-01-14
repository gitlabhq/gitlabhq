# frozen_string_literal: true

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

      desc 'Get SSH Key information' do
        success Entities::UserWithAdmin
      end
      params do
        requires :fingerprint, type: String, desc: 'Search for a SSH fingerprint'
      end
      get do
        authenticated_with_can_read_all_resources!

        key = KeysFinder.new(current_user, params).execute

        not_found!('Key') unless key

        if key.type == "DeployKey"
          present key, with: Entities::DeployKeyWithUser, current_user: current_user
        else
          present key, with: Entities::SSHKeyWithUser, current_user: current_user
        end
      rescue KeysFinder::InvalidFingerprint
        render_api_error!('Failed to return the key', 400)
      end
    end
  end
end
