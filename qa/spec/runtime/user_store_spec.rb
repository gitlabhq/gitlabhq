# frozen_string_literal: true

module QA
  RSpec.describe Runtime::UserStore do
    let(:default_admin_token) { "ypCa3Dzb23o5nvsixwPA" }

    before do
      allow(Runtime::Scenario).to receive(:send).with("gitlab_address").and_return("https://example.com")
      allow(Runtime::Logger).to receive_messages({
        debug: nil,
        info: nil,
        warn: nil,
        error: nil
      })
      allow(Runtime::Env).to receive_messages({
        admin_username: nil,
        admin_password: nil,
        admin_personal_access_token: nil
      })

      described_class.instance_variable_set(:@admin_api_client, nil)
      described_class.instance_variable_set(:@admin_user, nil)
    end

    def mock_user_get(token:, code: 200, body: { is_admin: true, id: 1, username: "root" }.to_json)
      allow(Support::API).to receive(:get).with("https://example.com/api/v4/user?private_token=#{token}").and_return(
        instance_double(RestClient::Response, code: code, body: body)
      )
    end

    describe "#admin_api_client" do
      let(:admin_token) { nil }

      before do
        allow(Runtime::Env).to receive(:admin_personal_access_token).and_return(admin_token)
      end

      context "when admin token variable is set" do
        let(:admin_token) { "admin-token" }

        before do
          mock_user_get(token: admin_token)
        end

        it "creates admin api client with configured token" do
          expect(described_class.admin_api_client.personal_access_token).to eq(admin_token)
        end
      end

      context "with valid default admin token and no token configured" do
        before do
          mock_user_get(token: default_admin_token)
        end

        it "creates admin api client with default admin token" do
          expect(described_class.admin_api_client.personal_access_token).to eq(default_admin_token)
        end
      end

      context "with invalid token set via environment variable" do
        let(:admin_token) { "admin-token" }

        before do
          mock_user_get(token: admin_token, code: 401, body: "401 Unauthorized")
        end

        it "raises InvalidTokenError" do
          expect { described_class.admin_api_client }.to raise_error(
            described_class::InvalidTokenError, "Admin token validation failed! Code: 401, Err: '401 Unauthorized'"
          )
        end
      end

      context "with expired admin password" do
        let(:admin_token) { "admin-token" }

        before do
          mock_user_get(token: admin_token, code: 403, body: "Your password expired")
        end

        it "raises ExpiredAdminPasswordError" do
          expect { described_class.admin_api_client }.to raise_error(
            described_class::ExpiredAdminPasswordError, "Admin password has expired and must be reset"
          )
        end
      end

      context "with token creation via UI" do
        let(:admin_user) { Resource::User.new }
        let(:pat) { Resource::PersonalAccessToken.init { |pat| pat.token = "test" } }

        before do
          allow(Resource::User).to receive(:init).and_yield(admin_user).and_return(admin_user)
          allow(Resource::PersonalAccessToken).to receive(:fabricate_via_browser_ui!).and_yield(pat).and_return(pat)
          allow(Flow::Login).to receive(:while_signed_in).with(as: admin_user).and_yield
          allow(admin_user).to receive(:reload!)

          mock_user_get(token: default_admin_token, code: 401)
          mock_user_get(token: pat.token)
        end

        it "creates admin api client with token created from UI" do
          expect(described_class.admin_api_client.personal_access_token).to eq(pat.token)
          expect(admin_user.username).to eq("root")
          expect(admin_user.password).to eq("5iveL!fe")
          expect(admin_user).to have_received(:reload!)
        end
      end
    end

    describe "#admin_user" do
      context "when admin client has not been initialized" do
        context "with admin user variables set" do
          let(:username) { "admin-username" }
          let(:password) { "admin-password" }

          before do
            allow(Runtime::Env).to receive_messages({ admin_username: username, admin_password: password })
          end

          it "returns admin user with configured credentials" do
            expect(described_class.admin_user.username).to eq(username)
            expect(described_class.admin_user.password).to eq(password)
          end
        end

        context "without admin user variables set" do
          let(:username) { "root" }
          let(:password) { "5iveL!fe" }

          it "returns admin user with default credentials" do
            expect(described_class.admin_user.username).to eq(username)
            expect(described_class.admin_user.password).to eq(password)
          end
        end
      end

      context "when admin client has been initialized" do
        let(:admin_user) { Resource::User.new }
        let(:admin_client) { Runtime::API::Client.new(personal_access_token: default_admin_token) }

        before do
          allow(Resource::User).to receive(:init).and_yield(admin_user).and_return(admin_user)
          allow(admin_user).to receive(:reload!)

          described_class.instance_variable_set(:@admin_api_client, admin_client)
        end

        context "with valid admin client belonging to user" do
          before do
            mock_user_get(token: default_admin_token)
          end

          it "sets api client on admin user and reloads it" do
            expect(described_class.admin_user.instance_variable_get(:@api_client)).to eq(admin_client)
            expect(admin_user).to have_received(:reload!)
          end
        end

        context "with valid admin client not belonging to user" do
          before do
            mock_user_get(token: default_admin_token, body: { username: "test" }.to_json)
          end

          it "prints warning message" do
            described_class.initialize_admin_user

            expect(Runtime::Logger).to have_received(:warn).with(<<~WARN)
              Configured global admin token does not belong to configured admin user
              Please check values for GITLAB_QA_ADMIN_ACCESS_TOKEN, GITLAB_ADMIN_USERNAME and GITLAB_ADMIN_PASSWORD variables
            WARN
          end
        end

        context "with invalid admin client" do
          before do
            mock_user_get(token: default_admin_token, code: 403, body: "Unauthorized")
          end

          it "raises invalid token error" do
            expect { described_class.admin_user }.to raise_error(
              described_class::InvalidTokenError, "Token validation failed! Code: 403, Err: 'Unauthorized'"
            )
          end
        end
      end
    end
  end
end
