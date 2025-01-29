# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', :skip_live_env, requires_admin: 'creates users and instance OAuth application',
    only: { condition: -> { Runtime::Env.release } },
    product_group: :authentication, quarantine: {
      type: :investigating,
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/515686'
    } do
    let!(:user) { Runtime::User::Store.test_user }
    let(:consumer_host) { "http://#{consumer_name}.#{Runtime::Env.running_in_ci? ? 'test' : 'bridge'}" }

    let(:instance_oauth_app) do
      Resource::InstanceOauthApplication.fabricate! do |application|
        application.redirect_uri = redirect_uri
        application.scopes = scopes
      end
    end

    after do
      instance_oauth_app.remove_via_api!
      save_gitlab_logs(consumer_name)
      remove_gitlab_service(consumer_name)
    end

    def run_gitlab_service(name:, app_id:, app_secret:)
      Service::DockerRun::Gitlab.new(
        image: Runtime::Env.release,
        name: name,
        omnibus_config: omnibus_configuration(app_id: app_id, app_secret: app_secret)).tap do |gitlab|
        gitlab.login
        gitlab.pull
        gitlab.register!
      end
    end

    # Copy GitLab logs from inside the named Docker container running the GitLab OAuth instance
    def save_gitlab_logs(name)
      Service::DockerRun::Gitlab.new(name: name).extract_service_logs
    end

    def remove_gitlab_service(name)
      Service::DockerRun::Gitlab.new(name: name).remove!
    end

    def wait_for_service(service)
      Support::Waiter.wait_until(max_duration: 900, sleep_interval: 5, raise_on_failure: true) do
        service.health == "healthy"
      end
    end

    shared_examples 'Instance OAuth Application' do |app_type, testcase|
      it "creates #{app_type} application and uses it to login", testcase: testcase do
        instance_oauth_app

        Page::Main::Menu.perform(&:sign_out_if_signed_in)

        app_id = instance_oauth_app.application_id
        app_secret = instance_oauth_app.application_secret

        consumer_gitlab_service = run_gitlab_service(name: consumer_name, app_id: app_id, app_secret: app_secret)

        wait_for_service(consumer_gitlab_service)

        page.visit consumer_host

        expect(page.driver.current_url).to include(consumer_host)

        Page::Main::Login.perform do |login_page|
          login_page.public_send(:"sign_in_with_gitlab_#{app_type}")
        end

        expect(page.driver.current_url).to include(Runtime::Scenario.gitlab_address)

        Flow::Login.sign_in(as: user, skip_page_validation: true)

        expect(page.driver.current_url).to include(consumer_host)

        Page::Dashboard::Welcome.perform do |welcome|
          expect(welcome).to have_welcome_title("Welcome to GitLab")
        end
      end
    end

    describe 'OIDC' do
      let(:consumer_name) { 'gitlab-oidc-consumer' }
      let(:redirect_uri) { "#{consumer_host}/users/auth/openid_connect/callback" }
      let(:scopes) { %w[openid profile email] }

      def omnibus_configuration(app_id:, app_secret:)
        <<~OMNIBUS
          gitlab_rails['initial_root_password']='5iveL\!fe';
          gitlab_rails['omniauth_enabled'] = true;
          gitlab_rails['omniauth_allow_single_sign_on'] = true;
          gitlab_rails['omniauth_block_auto_created_users'] = false;
          gitlab_rails['omniauth_providers'] = [
            {
              name: 'openid_connect',
              label: 'GitLab OIDC',
              args: {
                name: 'openid_connect',
                scope: ['openid','profile','email'],
                response_type: 'code',
                issuer: '#{Runtime::Scenario.gitlab_address}',
                discovery: false,
                uid_field: 'preferred_username',
                send_scope_to_token_endpoint: 'false',
                client_options: {
                  identifier: '#{app_id}',
                  secret: '#{app_secret}',
                  redirect_uri: '#{consumer_host}/users/auth/openid_connect/callback',
                  jwks_uri: '#{Runtime::Scenario.gitlab_address}/oauth/discovery/keys',
                  userinfo_endpoint: '#{Runtime::Scenario.gitlab_address}/oauth/userinfo',
                  token_endpoint: '#{Runtime::Scenario.gitlab_address}/oauth/token',
                  authorization_endpoint: '#{Runtime::Scenario.gitlab_address}/oauth/authorize'
                }
              }
            }
          ];
        OMNIBUS
      end

      # The host GitLab instance with address Runtime::Scenario.gitlab_address is the OIDC idP - OIDC application will
      # be created here.
      # GitLab instance stood up in docker with address gitlab-oidc-consumer.test (or gitlab-oidc-consumer.bridge) is
      # the consumer - The GitLab OIDC Login button will be displayed here.
      it_behaves_like 'Instance OAuth Application', :oidc, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/405137'
    end

    describe 'OAuth' do
      let(:consumer_name) { 'gitlab-oauth-consumer' }
      let(:redirect_uri) { "#{consumer_host}/users/auth/gitlab/callback" }
      let(:scopes) { %w[read_user] }

      def omnibus_configuration(app_id:, app_secret:)
        <<~OMNIBUS
          gitlab_rails['initial_root_password']='5iveL\!fe';
          gitlab_rails['omniauth_enabled'] = true;
          gitlab_rails['omniauth_allow_single_sign_on'] = true;
          gitlab_rails['omniauth_block_auto_created_users'] = false;
          gitlab_rails['omniauth_providers'] = [
            {
              name: 'gitlab',
              label: 'GitLab OAuth',
              app_id: '#{app_id}',
              app_secret: '#{app_secret}',
              args: {
                scope: 'read_user',
                client_options: {
                  site: '#{Runtime::Scenario.gitlab_address}'
                }
              }
            }
          ];
        OMNIBUS
      end

      # The host GitLab instance with address Runtime::Scenario.gitlab_address is the OAuth idP - OAuth application will
      # be created here.
      # GitLab instance stood up in docker with address gitlab-oauth-consumer.test (or gitlab-oauth-consumer.bridge) is
      # the consumer - The GitLab OAuth Login button will be displayed here.
      it_behaves_like 'Instance OAuth Application', :oauth, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412111'
    end
  end
end
