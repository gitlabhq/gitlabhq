# frozen_string_literal: true

require 'securerandom'

module QA
  describe 'Groups API' do
    before(:context) do
      @api_client = Runtime::API::Client.new(:gitlab)
      @personal_access_token = Runtime::API::Client.new.get_personal_access_token
    end

    let(:random_string) { SecureRandom.hex(8) }
    let(:group_name) { "api-group-name-#{random_string}" }
    let(:group_path) { "api-group-path-#{random_string}" }
    let(:description) { 'This is a test group' }

    let(:updated_group_name) { "updated-#{group_name}" }
    let(:updated_group_path) { "updated-#{group_path}" }
    let(:updated_description) { "updated-#{description}" }

    it 'Creates, updates and deletes a group' do
      @api_client = Runtime::API::Client.new(:gitlab, personal_access_token: @personal_access_token)

      groups_request = Runtime::API::Request.new(@api_client, "/groups")

      expected_response = {
          name: group_name,
          path: group_path,
          description: description,
          full_name: group_name,
          full_path: group_path
      }

      # Create
      post groups_request.url, name: group_name, path: group_path, description: description
      expect_status(201)

      expect(json_body).to match a_hash_including(expected_response)

      expected_response[:id] = created_group_id = json_body[:id]

      get groups_request.url
      expect_status(200)
      expect(json_body).to include a_hash_including(expected_response)

      expected_response = {
          name: updated_group_name,
          path: updated_group_path,
          description: updated_description,
          full_name: updated_group_name,
          full_path: updated_group_path
      }

      # Update
      group_request_by_id = Runtime::API::Request.new(@api_client, "/groups/#{created_group_id}")

      put group_request_by_id.url,
          name: updated_group_name,
          path: updated_group_path,
          description: updated_description

      expect_status(200)

      expect(json_body).to match a_hash_including(expected_response)

      get group_request_by_id.url
      expect_status(200)
      expect(json_body).to match a_hash_including(expected_response)

      # Delete
      delete group_request_by_id.url
      expect_status(202)

      get groups_request.url
      expect_status(200)
      expect(json_body).not_to include a_hash_including(id: created_group_id)

      get group_request_by_id.url
      expect_status(404)
      expect(json_body).to match({ message: "404 Group Not Found" })
    end
  end
end
