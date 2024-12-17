# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    include Support::API

    describe 'Users API', :smoke, product_group: :tenant_scale do
      let(:api_client) { Runtime::User::Store.test_user.api_client }
      let(:username) { Runtime::User::Store.test_user.username }

      it 'GET /users', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347882' do
        request = Runtime::API::Request.new(api_client, '/users')
        response = Support::API.get(request.url)

        expect(response.code).to eq(Support::API::HTTP_STATUS_OK)
      end

      it 'GET /users/:username with a valid username',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347886' do
        request = Runtime::API::Request.new(api_client, '/users', username: username)
        response = Support::API.get(request.url)
        response_body = parse_body(response)

        expect(response.code).to eq(Support::API::HTTP_STATUS_OK)
        expect(response_body).to contain_exactly(a_hash_including(username: username))
      end

      it 'GET /users/:username with an invalid username',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347883' do
        request = Runtime::API::Request.new(api_client, '/users', username: SecureRandom.hex(10))
        response = Support::API.get(request.url)
        response_body = parse_body(response)

        expect(response.code).to eq(Support::API::HTTP_STATUS_OK)
        expect(response_body).to eq([])
      end
    end
  end
end
