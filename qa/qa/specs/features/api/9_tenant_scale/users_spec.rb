# frozen_string_literal: true

module QA
  RSpec.describe 'Tenant Scale', feature_category: :organization do
    include Support::API

    describe 'Users API', :smoke do
      let(:api_client) { Runtime::User::Store.test_user.api_client }
      let(:username) { Runtime::User::Store.test_user.username }

      it 'GET /users' do
        request = Runtime::API::Request.new(api_client, '/users')
        response = Support::API.get(request.url)

        expect(response.code).to eq(Support::API::HTTP_STATUS_OK)
      end

      it 'GET /users/:username with a valid username' do
        request = Runtime::API::Request.new(api_client, '/users', username: username)
        response = Support::API.get(request.url)
        response_body = parse_body(response)

        expect(response.code).to eq(Support::API::HTTP_STATUS_OK)
        expect(response_body).to contain_exactly(a_hash_including(username: username))
      end

      it 'GET /users/:username with an invalid username' do
        request = Runtime::API::Request.new(api_client, '/users', username: SecureRandom.hex(10))
        response = Support::API.get(request.url)
        response_body = parse_body(response)

        expect(response.code).to eq(Support::API::HTTP_STATUS_OK)
        expect(response_body).to eq([])
      end
    end
  end
end
