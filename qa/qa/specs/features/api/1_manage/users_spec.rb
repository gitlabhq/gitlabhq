# frozen_string_literal: true

require 'airborne'

module QA
  RSpec.describe 'Manage' do
    describe 'Users API' do
      let(:api_client) { Runtime::API::Client.new(:gitlab) }
      let(:request) { Runtime::API::Request.new(api_client, '/users') }

      it 'GET /users', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/460' do
        get request.url

        expect_status(200)
      end

      it 'GET /users/:username with a valid username', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/480' do
        get request.url, { params: { username: Runtime::User.username } }

        expect_status(200)
        expect(json_body).to contain_exactly(
          a_hash_including(username: Runtime::User.username)
        )
      end

      it 'GET /users/:username with an invalid username', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/462' do
        get request.url, { params: { username: SecureRandom.hex(10) } }

        expect_status(200)
        expect(json_body).to eq([])
      end
    end
  end
end
