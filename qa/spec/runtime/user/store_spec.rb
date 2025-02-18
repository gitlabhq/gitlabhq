# frozen_string_literal: true

module QA
  RSpec.describe Runtime::User::Store do
    include QA::Support::Helpers::StubEnv

    let(:default_admin_token) { "ypCa3Dzb23o5nvsixwPA" }

    before do
      allow(Runtime::Env).to receive(:personal_access_tokens_disabled?).and_return(false)
      allow(Runtime::Scenario).to receive(:send).with("gitlab_address").and_return("https://example.com")
      allow(Runtime::Logger).to receive_messages({
        debug: nil,
        info: nil,
        warn: nil,
        error: nil
      })

      # Clear the global state before each spec execution
      if described_class.instance_variable_defined?(:@admin_api_client)
        described_class.send(:remove_instance_variable, :@admin_api_client)
      end

      if described_class.instance_variable_defined?(:@admin_user)
        described_class.send(:remove_instance_variable, :@admin_user)
      end

      if described_class.instance_variable_defined?(:@user_api_client)
        described_class.send(:remove_instance_variable, :@user_api_client)
      end

      if described_class.instance_variable_defined?(:@test_user)
        described_class.send(:remove_instance_variable, :@test_user)
      end

      described_class.instance_variable_set(:@admin_username, nil)
      described_class.instance_variable_set(:@admin_password, nil)
      described_class.instance_variable_set(:@admin_api_token, nil)
    end

    def mock_user_get(token:, code: 200, body: { is_admin: true, id: 1, username: "root" }.to_json)
      allow(Support::API).to receive(:get).with("https://example.com/api/v4/user?private_token=#{token}").and_return(
        instance_double(RestClient::Response, code: code, body: body)
      )
    end

    describe "#admin_api_client" do
      let(:admin_token) { nil }
      let(:no_admin_env) { false }

      before do
        stub_env("GITLAB_ADMIN_USERNAME", nil)
        stub_env("GITLAB_ADMIN_PASSWORD", nil)
        stub_env("GITLAB_QA_ADMIN_ACCESS_TOKEN", admin_token)

        allow(Runtime::Env).to receive(:no_admin_environment?).and_return(no_admin_env)
      end

      context "with no admin env" do
        let(:no_admin_env) { true }

        it "sets admin api client to nil" do
          expect(described_class.admin_api_client).to be_nil
        end
      end

      context "with personal access tokens disabled" do
        before do
          allow(Runtime::Env).to receive(:personal_access_tokens_disabled?).and_return(true)
        end

        it "sets admin api client to nil" do
          expect(described_class.admin_api_client).to be_nil
        end
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
            Runtime::User::InvalidTokenError, "API client validation failed! Code: 401, Err: '401 Unauthorized'"
          )
        end
      end

      context "with expired admin password" do
        let(:admin_token) { "admin-token" }

        before do
          mock_user_get(token: admin_token, code: 403, body: "Your password expired")
        end

        it "raises ExpiredPasswordError" do
          expect { described_class.admin_api_client }.to raise_error(
            Runtime::User::ExpiredPasswordError, "Password for client's user has expired and must be reset"
          )
        end
      end

      context "with invalid default admin user credentials" do
        before do
          mock_user_get(token: default_admin_token, code: 404, body: "error")

          allow(Resource::PersonalAccessToken).to receive(:fabricate_via_browser_ui!).and_raise(
            Runtime::User::InvalidCredentialsError
          )
        end

        it "returns nil" do
          expect(described_class.admin_api_client).to be_nil
        end
      end

      context "with invalid explicitly configured admin user credentials" do
        let(:admin_token) { nil }

        before do
          stub_env("GITLAB_ADMIN_USERNAME", "test")
          stub_env("GITLAB_ADMIN_PASSWORD", "test")

          mock_user_get(token: Runtime::User::Data::DEFAULT_ADMIN_API_TOKEN, code: 401, body: "401 Unauthorized")
          allow(Resource::PersonalAccessToken).to receive(:fabricate_via_browser_ui!).and_raise(
            Runtime::User::InvalidCredentialsError
          )
        end

        it "raises InvalidCredentialsError" do
          expect { described_class.admin_api_client }.to raise_error(Runtime::User::InvalidCredentialsError)
        end
      end

      context "with token creation via UI" do
        let(:token) { "token" }

        # dummy objects are created with populated id fields to simulate proper fabrication and reload calls
        let(:admin_user) { Resource::User.init { |u| u.id = 1 } }

        let(:pat) do
          Resource::PersonalAccessToken.init do |p|
            p.token = token
            p.user_id = 1
          end
        end

        before do
          allow(Resource::User).to receive(:init).and_yield(admin_user).and_return(admin_user)
          allow(Resource::PersonalAccessToken).to receive(:fabricate_via_browser_ui!).and_yield(pat).and_return(pat)
          allow(admin_user).to receive(:reload!)

          mock_user_get(token: default_admin_token, code: 401)
        end

        it "creates admin api client with token created from UI" do
          expect(described_class.admin_api_client.personal_access_token).to eq(token)
          expect(pat.username).to eq("root")
          expect(pat.password).to eq("5iveL!fe")
          expect(admin_user).to have_received(:reload!)
        end
      end
    end

    describe "#admin_user" do
      let(:no_admin_env) { false }

      before do
        stub_env("GITLAB_ADMIN_USERNAME", nil)
        stub_env("GITLAB_ADMIN_PASSWORD", nil)
        stub_env("GITLAB_QA_ADMIN_ACCESS_TOKEN", nil)

        allow(Runtime::Env).to receive(:no_admin_environment?).and_return(no_admin_env)
      end

      context "with no admin env" do
        let(:no_admin_env) { true }

        it "sets admin user to nil" do
          expect(described_class.admin_user).to be_nil
        end
      end

      context "when admin client has not been initialized" do
        context "with admin user variables set" do
          let(:username) { "admin-username" }
          let(:password) { "admin-password" }

          before do
            stub_env("GITLAB_ADMIN_USERNAME", username)
            stub_env("GITLAB_ADMIN_PASSWORD", password)
          end

          it "returns admin user with configured credentials" do
            expect(described_class.admin_user.username).to eq(username)
            expect(described_class.admin_user.password).to eq(password)
            expect(described_class.admin_user.admin?).to be(true)
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
              Configured api client does not belong to the user
              Please check values for user authentication related variables
            WARN
          end
        end

        context "with invalid admin client" do
          before do
            mock_user_get(token: default_admin_token, code: 403, body: "Unauthorized")
          end

          it "raises invalid token error" do
            expect { described_class.admin_user }.to raise_error(
              Runtime::User::InvalidTokenError, "API client validation failed! Code: 403, Err: 'Unauthorized'"
            )
          end
        end
      end
    end

    describe "#user_api_client" do
      subject(:user_api_client) { described_class.user_api_client }

      context "when running on live environment" do
        let(:username) { "username" }
        let(:password) { "password" }
        let(:api_token) { "token" }

        before do
          stub_env("GITLAB_USERNAME", username)
          stub_env("GITLAB_PASSWORD", password)
          stub_env("GITLAB_QA_ACCESS_TOKEN", api_token)

          allow(Runtime::Env).to receive(:running_on_dot_com?).and_return(true)
        end

        context "with personal access tokens disabled" do
          before do
            allow(Runtime::Env).to receive(:personal_access_tokens_disabled?).and_return(true)
          end

          it "sets api client to nil" do
            expect(described_class.user_api_client).to be_nil
          end
        end

        context "when api token variable is set" do
          before do
            mock_user_get(token: api_token)
          end

          it "creates api client with configured token" do
            expect(user_api_client.personal_access_token).to eq(api_token)
          end
        end

        context "with invalid token set via environment variable" do
          before do
            mock_user_get(token: api_token, code: 401, body: "401 Unauthorized")
          end

          it "raises invalid token error" do
            expect { user_api_client }.to raise_error(
              Runtime::User::InvalidTokenError,
              "API client validation failed! Code: 401, Err: '401 Unauthorized'"
            )
          end
        end

        context "with expired admin password" do
          before do
            mock_user_get(token: api_token, code: 403, body: "Your password expired")
          end

          it "raises expired password error" do
            expect { user_api_client }.to raise_error(
              Runtime::User::ExpiredPasswordError,
              "Password for client's user has expired and must be reset"
            )
          end
        end

        context "with token creation via UI" do
          let(:api_token) { nil }
          # dummy objects are created with populated id fields to simulate proper fabrication and reload calls
          let(:user_spy) { Resource::User.init { |u| u.id = 1 } }

          let(:pat) do
            Resource::PersonalAccessToken.init do |p|
              p.token = "token"
              p.user_id = 1
            end
          end

          before do
            allow(Resource::User).to receive(:init).and_yield(user_spy).and_return(user_spy)
            allow(Resource::PersonalAccessToken).to receive(:fabricate_via_browser_ui!).and_yield(pat).and_return(pat)
            allow(user_spy).to receive(:reload!)
          end

          it "creates user api client with token created from UI" do
            expect(user_api_client.personal_access_token).to eq(pat.token)
            expect(pat.username).to eq(username)
            expect(pat.password).to eq(password)
            expect(user_spy).to have_received(:reload!)
          end
        end
      end

      context "when running on ephemeral environment with working admin client" do
        let(:admin_api_client) { instance_double(Runtime::API::Client) }
        let(:user) { Resource::User.init { |usr| usr.api_client = instance_double(Runtime::API::Client) } }

        before do
          allow(Runtime::Env).to receive(:running_on_live_env?).and_return(false)

          described_class.instance_variable_set(:@admin_api_client, admin_api_client)
          described_class.instance_variable_set(:@test_user, user)
        end

        it "returns test user api client" do
          expect(user_api_client).to eq(user.api_client)
        end
      end
    end

    describe "#test_user" do
      subject(:test_user) { described_class.test_user }

      let(:username) { "username" }
      let(:password) { "password" }

      before do
        stub_env("GITLAB_USERNAME", username)
        stub_env("GITLAB_PASSWORD", password)
      end

      context "when unique test user creation is disabled" do
        before do
          stub_env("QA_CREATE_UNIQUE_TEST_USERS", false)
        end

        context "with user variables set" do
          it "returns user with configured credentials" do
            expect(test_user.username).to eq(username)
            expect(test_user.password).to eq(password)
          end
        end

        context "without user variables set" do
          let(:username) { nil }
          let(:password) { nil }

          it "raises error" do
            expect { test_user }.to raise_error <<~ERR
              Missing global test user credentials,
              please set 'GITLAB_USERNAME' and 'GITLAB_PASSWORD' environment variables
            ERR
          end
        end
      end

      context "when running on live environment" do
        before do
          stub_env("GITLAB_QA_ACCESS_TOKEN", nil)

          allow(Runtime::Env).to receive(:running_on_dot_com?).and_return(true)
        end

        context "when api client has not been initialized" do
          context "with user variables set" do
            it "returns user with configured credentials" do
              expect(test_user.username).to eq(username)
              expect(test_user.password).to eq(password)
            end
          end

          context "without user variables set" do
            let(:username) { nil }
            let(:password) { nil }

            it "raises error" do
              expect { test_user }.to raise_error <<~ERR
                Missing global test user credentials,
                please set 'GITLAB_USERNAME' and 'GITLAB_PASSWORD' environment variables
              ERR
            end
          end

          context "with only username set" do
            let(:password) { nil }

            it "raises error" do
              expect { test_user }.to raise_error <<~ERR
                Missing global test user credentials,
                please set 'GITLAB_USERNAME' and 'GITLAB_PASSWORD' environment variables
              ERR
            end
          end

          context "with only password set" do
            let(:username) { nil }

            it "raises error" do
              expect { test_user }.to raise_error <<~ERR
                Missing global test user credentials,
                please set 'GITLAB_USERNAME' and 'GITLAB_PASSWORD' environment variables
              ERR
            end
          end
        end

        context "when api client has been initialized" do
          let(:user_spy) { Resource::User.new }
          let(:api_client) { Runtime::API::Client.new(personal_access_token: "token") }

          before do
            allow(Resource::User).to receive(:init).and_yield(user_spy).and_return(user_spy)
            allow(user_spy).to receive(:reload!)

            described_class.instance_variable_set(:@user_api_client, api_client)
          end

          context "with valid client belonging to user" do
            before do
              mock_user_get(token: api_client.personal_access_token, body: { username: username }.to_json)
            end

            it "sets api client on user and reloads it" do
              expect(test_user.api_client).to eq(api_client)
              expect(test_user).to have_received(:reload!)
            end
          end

          context "with valid client not belonging to user" do
            before do
              mock_user_get(token: api_client.personal_access_token, body: { username: "test" }.to_json)
            end

            it "prints warning message" do
              described_class.initialize_test_user

              expect(Runtime::Logger).to have_received(:warn).with(<<~WARN)
                Configured api client does not belong to the user
                Please check values for user authentication related variables
              WARN
            end
          end

          context "with invalid api client" do
            before do
              mock_user_get(token: api_client.personal_access_token, code: 403, body: "Unauthorized")
            end

            it "raises invalid token error" do
              expect { test_user }.to raise_error(
                Runtime::User::InvalidTokenError,
                "API client validation failed! Code: 403, Err: 'Unauthorized'"
              )
            end
          end
        end
      end

      context "when running on ephemeral environment with working admin client" do
        let(:admin_api_client) { instance_double(Runtime::API::Client) }
        let(:user) { Resource::User.new }

        before do
          allow(Runtime::Env).to receive(:running_on_live_env?).and_return(false)
          allow(Resource::User).to receive(:fabricate!).and_yield(user).and_return(user)

          described_class.instance_variable_set(:@admin_api_client, admin_api_client)
        end

        it "creates new user" do
          expect(test_user).to eq(user)
          # check admin api client was explicitly used for user creation
          expect(test_user.api_client).to eq(admin_api_client)
        end
      end
    end

    describe "#additional_test_user" do
      subject(:test_user) { described_class.additional_test_user }

      let(:username) { "username" }
      let(:password) { "password" }

      before do
        stub_env("GITLAB_QA_USERNAME_1", username)
        stub_env("GITLAB_QA_PASSWORD_1", password)

        allow(Runtime::Env).to receive(:personal_access_tokens_disabled?).and_return(false)
      end

      context "with admin api client" do
        let(:user_spy) { Resource::User.new }
        let(:api_client) { Runtime::API::Client.new(personal_access_token: "token") }

        before do
          allow(Resource::User).to receive(:fabricate!).and_yield(user_spy).and_return(user_spy)
          described_class.instance_variable_set(:@admin_api_client, api_client)
        end

        it "creates new user" do
          expect(test_user).to eq(user_spy)
        end
      end

      context "without admin api client" do
        let(:user_spy) { Resource::User.new }

        before do
          allow(Resource::User).to receive(:init).and_yield(user_spy).and_return(user_spy)
          allow(user_spy).to receive(:reload!).and_return(user_spy)

          described_class.instance_variable_set(:@admin_api_client, nil)
        end

        context "with credentials" do
          it "returns user with predefined credentials" do
            expect(test_user.username).to eq(username)
            expect(test_user.password).to eq(password)
          end
        end

        context "with missing username credential" do
          let(:username) { nil }

          it "raises MissingUserCredentialError" do
            expect { test_user }.to raise_error(
              Runtime::User::MissingUserCredentialError,
              "Missing 'GITLAB_QA_USERNAME_1' environment variable"
            )
          end
        end

        context "with missing password credential" do
          let(:password) { nil }

          it "raises MissingUserCredentialError" do
            expect { test_user }.to raise_error(
              Runtime::User::MissingUserCredentialError,
              "Missing 'GITLAB_QA_PASSWORD_1' environment variable"
            )
          end
        end
      end
    end
  end
end
