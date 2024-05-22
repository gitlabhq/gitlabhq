# frozen_string_literal: true

module API
  # Keys API
  class Keys < ::API::Base
    before { authenticate! }

    feature_category :system_access

    resource :keys do
      desc 'Get single ssh key by id. Only available to admin users' do
        detail 'Get SSH key with user by ID of an SSH key. Note only administrators can lookup SSH key with user by ID\
        of an SSH key'
        success Entities::SSHKeyWithUser
      end
      params do
        requires :id, types: [String, Integer], desc: 'The ID of an SSH key', documentation: { example: '2' }
      end
      get ":id" do
        authenticated_as_admin!

        key = Key.find(params[:id])

        present key, with: Entities::SSHKeyWithUser, current_user: current_user
      end

      desc 'Get user by fingerprint of SSH key' do
        success Entities::UserWithAdmin
        detail 'You can search for a user that owns a specific SSH key. Note only administrators can lookup SSH key\
        with the fingerprint of an SSH key'
      end
      params do
        requires :fingerprint, type: String, desc: 'The fingerprint of an SSH key',
          documentation: { example: 'ba:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d1' }
      end
      get do
        authenticated_with_can_read_all_resources!

        key = KeysFinder.new(params).execute

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
