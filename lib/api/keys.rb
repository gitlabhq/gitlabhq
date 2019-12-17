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

        finder_params = params.merge(key_type: 'ssh')

        key = KeysFinder.new(current_user, finder_params).execute

        not_found!('Key') unless key
        present key, with: Entities::SSHKeyWithUser, current_user: current_user
      rescue KeysFinder::InvalidFingerprint
        render_api_error!('Failed to return the key', 400)
      end
    end
  end
end
