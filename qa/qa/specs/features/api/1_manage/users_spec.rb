# frozen_string_literal: true

module QA
  context :manage do
    describe 'Users API' do
      before(:context) do
        @api_client = Runtime::API::Client.new(:gitlab)
      end

      let(:request) { Runtime::API::Request.new(@api_client, '/users') }

      it 'GET /users' do
        get request.url

        expect_status(200)
      end

      it 'GET /users/:username with a valid username' do
        get request.url, { params: { username: Runtime::User.username } }

        expect_status(200)
        expect(json_body).to contain_exactly(
          a_hash_including(username: Runtime::User.username)
        )
      end

      it 'GET /users/:username with an invalid username' do
        get request.url, { params: { username: SecureRandom.hex(10) } }

        expect_status(200)
        expect(json_body).to eq([])
      end
    end
  end
end
