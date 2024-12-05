# frozen_string_literal: true

RSpec.describe QA::Resource::User do
  subject(:user) { described_class }

  describe "#fabricate_via_api!" do
    let(:address) { "https://example.com" }
    let(:token) { "foo" }
    let(:request_args) { { url: "#{address}/api/v4/user?private_token=#{token}", verify_ssl: false } }

    let(:body) do
      {
        id: '0',
        name: 'name',
        username: 'name',
        web_url: '',
        email: "test@email.com"
      }
    end

    def response(resp_body, code: 200)
      instance_double(RestClient::Response, code: code, body: resp_body.to_json)
    end

    def url(path)
      "#{path}private_token=#{token}"
    end

    before do
      allow(QA::Runtime::Scenario).to receive(:gitlab_address).and_return(address)
      allow(QA::Runtime::User::Store).to receive(:admin_api_client).and_return(
        QA::Runtime::API::Client.new(personal_access_token: token)
      )

      allow(RestClient::Request).to receive(:execute)
        .with({ method: :get, url: "#{address}/api/v4/#{url('user?')}", verify_ssl: false })
        .and_return(response(body))
    end

    context "with existing user" do
      it "return existing user" do
        resource = user.fabricate_via_api! do |u|
          u.username = 'name'
        end

        expect(resource.id).to eq("0")
      end
    end

    context "with token no belonging to user" do
      let(:existing_user) do
        {
          id: '1',
          name: 'name',
          username: 'test',
          web_url: '',
          email: "test@email.com"
        }
      end

      before do
        allow(RestClient::Request).to receive(:execute)
          .with(hash_including(method: :get, url: "#{address}/api/v4/#{url('users?username=test&')}"))
          .and_return(response([existing_user]))
        allow(RestClient::Request).to receive(:execute)
          .with(hash_including(method: :get, url: "#{address}/api/v4/#{url('users/1?')}"))
          .and_return(response(existing_user))
      end

      it "fetches existing user via id lookup" do
        resource = user.fabricate_via_api! do |u|
          u.username = 'test'
        end

        expect(resource.id).to eq("1")
      end
    end

    context "without existing user" do
      let(:existing_user) do
        {
          id: '1',
          name: 'name',
          username: 'test',
          web_url: '',
          email: "test@email.com"
        }
      end

      before do
        allow(RestClient::Request).to receive(:execute)
          .with(hash_including(method: :get, url: "#{address}/api/v4/#{url('users?username=test&')}"))
          .and_return(response([]))
        allow(RestClient::Request).to receive(:execute)
          .with(hash_including(method: :post, url: "#{address}/api/v4/#{url('users?')}"))
          .and_return(response(existing_user, code: 201))
      end

      it "fetches existing user via id lookup" do
        resource = user.fabricate_via_api! do |u|
          u.username = 'test'
        end

        expect(resource.id).to eq("1")
      end
    end
  end
end
