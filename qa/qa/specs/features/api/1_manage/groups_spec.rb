require 'securerandom'

module QA
  describe 'API basics' do

    before(:context) do
      @api_client = Runtime::API::Client.new(:gitlab)
      @personal_access_token = Runtime::API::Client.new.get_personal_access_token
    end

    let(:random_string) { SecureRandom.hex(8) }
    let(:group_name) { "api-group-name-#{random_string}" }
    let(:group_path) { "api-group-path-#{random_string}" }

    it 'user creates, updates and deletes a group' do

      @api_client = Runtime::API::Client.new(:gitlab, personal_access_token: @personal_access_token)

      groups_request = Runtime::API::Request.new(@api_client, "/groups")

      description = 'This is a test group'

      post groups_request.url, name: group_name, path: group_path, description: description
      expect_status(201)

      expect(json_body).to match(
        a_hash_including(
          name: group_name,
          path: group_path,
          description: description,
          visibility: 'private',
          lfs_enabled: true,
          request_access_enabled: false,
          full_name: group_name,
          full_path: group_path)
        )

      get groups_request.url
      expect_status(200)
      puts json_body.to_json

    end

  end
end
