# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin updates network settings', :request_store, :enable_admin_mode,
  feature_category: :rate_limiting do
  include StubENV
  include Features::SettingsHelpers

  let_it_be(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
    visit network_admin_application_settings_path
  end

  it 'changes Outbound requests settings' do
    within_testid('outbound-requests-content') do
      check 'Allow requests to the local network from webhooks and integrations'
      # Enabled by default
      uncheck 'Allow requests to the local network from system hooks'
      # Enabled by default
      uncheck 'Enforce DNS-rebinding attack protection'
    end

    expect_save_settings('outbound-requests-content')

    expect(current_settings.allow_local_requests_from_web_hooks_and_services).to be true
    expect(current_settings.allow_local_requests_from_system_hooks).to be false
    expect(current_settings.dns_rebinding_protection_enabled).to be false
  end

  it 'changes User and IP rate limits settings' do
    within_testid('ip-limits-content') do
      check 'Enable unauthenticated API request rate limit'
      fill_in 'Maximum unauthenticated API requests per rate limit period per IP', with: 100
      fill_in 'Unauthenticated API rate limit period in seconds', with: 200

      check 'Enable unauthenticated web request rate limit'
      fill_in 'Maximum unauthenticated web requests per rate limit period per IP', with: 300
      fill_in 'Unauthenticated web rate limit period in seconds', with: 400

      check 'Enable authenticated API request rate limit'
      fill_in 'Maximum authenticated API requests per rate limit period per user', with: 500
      fill_in 'Authenticated API rate limit period in seconds', with: 600

      check 'Enable authenticated web request rate limit'
      fill_in 'Maximum authenticated web requests per rate limit period per user', with: 700
      fill_in 'Authenticated web rate limit period in seconds', with: 800

      fill_in "Maximum authenticated requests to project/:id/jobs per minute", with: 1000

      fill_in 'Plain-text response to send to clients that hit a rate limit', with: 'Custom message'
    end

    expect_save_settings('ip-limits-content')

    expect(current_settings).to have_attributes(
      throttle_unauthenticated_api_enabled: true,
      throttle_unauthenticated_api_requests_per_period: 100,
      throttle_unauthenticated_api_period_in_seconds: 200,
      throttle_unauthenticated_enabled: true,
      throttle_unauthenticated_requests_per_period: 300,
      throttle_unauthenticated_period_in_seconds: 400,
      throttle_authenticated_api_enabled: true,
      throttle_authenticated_api_requests_per_period: 500,
      throttle_authenticated_api_period_in_seconds: 600,
      throttle_authenticated_web_enabled: true,
      throttle_authenticated_web_requests_per_period: 700,
      throttle_authenticated_web_period_in_seconds: 800,
      project_jobs_api_rate_limit: 1000,
      rate_limiting_response_text: 'Custom message'
    )
  end

  it 'changes authenticated Git HTTP rate limits settings' do
    # Default settings
    expect(current_settings.throttle_authenticated_git_http_enabled)
      .to be(false)
    expect(current_settings.throttle_authenticated_git_http_requests_per_period)
      .to eq(ApplicationSetting::DEFAULT_AUTHENTICATED_GIT_HTTP_PERIOD)
    expect(current_settings.throttle_authenticated_git_http_period_in_seconds)
      .to eq(ApplicationSetting::DEFAULT_AUTHENTICATED_GIT_HTTP_LIMIT)

    within_testid('git-http-limits-settings') do
      check 'Enable authenticated Git HTTP request rate limit'

      fill_in(
        'Maximum authenticated Git HTTP requests per period per user',
        with: ApplicationSetting::DEFAULT_AUTHENTICATED_GIT_HTTP_LIMIT + 1
      )

      fill_in(
        'Authenticated Git HTTP rate limit period in seconds',
        with: ApplicationSetting::DEFAULT_AUTHENTICATED_GIT_HTTP_PERIOD + 2
      )
    end

    expect_save_settings('git-http-limits-settings')

    expect(current_settings.throttle_authenticated_git_http_enabled)
      .to be(true)

    expect(current_settings.throttle_authenticated_git_http_requests_per_period)
      .to eq(ApplicationSetting::DEFAULT_AUTHENTICATED_GIT_HTTP_PERIOD + 1)

    expect(current_settings.throttle_authenticated_git_http_period_in_seconds)
      .to eq(ApplicationSetting::DEFAULT_AUTHENTICATED_GIT_HTTP_LIMIT + 2)
  end

  it 'changes Issues rate limits settings' do
    within_testid('issue-limits-settings') do
      fill_in 'Maximum number of requests per minute', with: 0
    end

    expect_save_settings('issue-limits-settings')

    expect(current_settings.issues_create_limit).to eq(0)
  end

  it 'changes Pipelines rate limits settings' do
    within_testid('pipeline-limits-settings') do
      fill_in 'Maximum number of requests per project, sha and user. Resets after 1 minute.', with: 10
      fill_in 'Maximum number of requests for a user. Resets after 1 minute.', with: 100
    end

    expect_save_settings('pipeline-limits-settings')

    expect(current_settings.pipeline_limit_per_project_user_sha).to eq(10)
    expect(current_settings.pipeline_limit_per_user).to eq(100)
  end

  it 'changes gitlab shell operation limits settings' do
    within_testid('gitlab-shell-operation-limits') do
      fill_in 'Maximum number of Git operations per minute', with: 100
    end

    expect_save_settings('gitlab-shell-operation-limits')

    expect(current_settings.gitlab_shell_operation_limit).to eq(100)
  end

  shared_examples 'API rate limit setting' do
    it 'changes the rate limits settings' do
      new_rate_limit = 1234
      within_testid(network_settings_section) do
        fill_in rate_limit_field, with: new_rate_limit
      end

      expect_save_settings(network_settings_section)

      expect(current_settings[application_setting_key]).to eq(new_rate_limit)
    end
  end

  describe 'users API rate limits' do
    let_it_be(:network_settings_section) { 'users-api-limits-settings' }

    context 'for GET /users:id API requests', :aggregate_failures do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user'), api_name: 'GET /users/:id',
          timeframe: '10 minutes')
      end

      let(:application_setting_key) { :users_get_by_id_limit }

      it 'changes Users API rate limits settings', :aggregate_failures do
        new_rate_limit = 0
        within_testid('users-api-limits-settings') do
          fill_in rate_limit_field, with: new_rate_limit
          fill_in 'Excluded users', with: 'someone, someone_else'
        end

        expect_save_settings('users-api-limits-settings')

        expect(current_settings[application_setting_key]).to eq(new_rate_limit)
        expect(current_settings.users_get_by_id_limit_allowlist).to eq(%w[someone someone_else])
      end
    end

    context 'for GET /users/:id/followers API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/followers', timeframe: 'minute')
      end

      let(:application_setting_key) { :users_api_limit_followers }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:id/following API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/following', timeframe: 'minute')
      end

      let(:application_setting_key) { :users_api_limit_following }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:user_id/status API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/status', timeframe: 'minute')
      end

      let(:application_setting_key) { :users_api_limit_status }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:user_id/keys API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/keys', timeframe: 'minute')
      end

      let(:application_setting_key) { :users_api_limit_ssh_keys }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:id/keys/:key_id API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/keys/:key_id', timeframe: 'minute')
      end

      let(:application_setting_key) { :users_api_limit_ssh_key }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:id/gpg_keys API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/gpg_keys', timeframe: 'minute')
      end

      let(:application_setting_key) { :users_api_limit_gpg_keys }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:id/gpg_keys/:key_id API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/gpg_keys/:key_id', timeframe: 'minute')
      end

      let(:application_setting_key) { :users_api_limit_gpg_key }

      it_behaves_like 'API rate limit setting'
    end
  end

  describe 'organizations API rate limits' do
    let_it_be(:network_settings_section) { 'organizations-api-limits-settings' }

    context 'for POST /organizations API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user'), api_name: 'POST /organizations',
          timeframe: 'minute')
      end

      let(:application_setting_key) { :create_organization_api_limit }

      it_behaves_like 'API rate limit setting'
    end
  end

  describe 'groups API rate limits' do
    let_it_be(:network_settings_section) { 'groups-api-limits-settings' }

    context 'for unauthenticated GET /groups API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :groups_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /groups/:id API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :group_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /groups/:id/projects API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id/projects', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :group_projects_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /groups/:id/groups/shared API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id/groups/shared', timeframe: 'minute')
      end

      let(:application_setting_key) { :group_shared_groups_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /groups/:id/invited_groups API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id/invited_groups', timeframe: 'minute')
      end

      let(:application_setting_key) { :group_invited_groups_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for POST /groups/:id/archive API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name1} and %{api_name2} APIs per %{timeframe} per user or IP address'),
          api_name1: 'POST /groups/:id/archive', api_name2: 'POST /groups/:id/unarchive', timeframe: 'minute')
      end

      let(:application_setting_key) { :group_archive_unarchive_api_limit }

      it_behaves_like 'API rate limit setting'
    end
  end

  describe 'projects API rate limits' do
    let_it_be(:network_settings_section) { 'projects-api-limits-settings' }

    context 'for unauthenticated GET /projects API requests' do
      let_it_be(:rate_limit_field) do
        format(
          _('Maximum requests to the %{api_name} API per %{timeframe} per IP address for unauthenticated requests'),
          api_name: 'GET /projects',
          timeframe: '10 minutes'
        )
      end

      let_it_be(:application_setting_key) { :projects_api_rate_limit_unauthenticated }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /projects API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user for authenticated requests'),
          api_name: 'GET /projects', timeframe: '10 minutes')
      end

      let_it_be(:application_setting_key) { :projects_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /projects/:id API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /projects/:id', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :project_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /projects/:id/members/all API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /projects/:id/members/all', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :project_members_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /projects/:id/invited_groups API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /projects/:id/invited_groups', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :project_invited_groups_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:user_id/projects API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/projects', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :user_projects_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:user_id/contributed_projects API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/contributed_projects', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :user_contributed_projects_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:user_id/starred_projects API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/starred_projects', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :user_starred_projects_api_limit }

      it_behaves_like 'API rate limit setting'
    end
  end

  shared_examples 'regular throttle rate limit settings' do
    it 'changes rate limit settings' do
      within_testid(selector) do
        check 'Enable unauthenticated API request rate limit'
        fill_in 'Maximum unauthenticated API requests per rate limit period per IP', with: 12
        fill_in 'Unauthenticated API rate limit period in seconds', with: 34

        check 'Enable authenticated API request rate limit'
        fill_in 'Maximum authenticated API requests per rate limit period per user', with: 56
        fill_in 'Authenticated API rate limit period in seconds', with: 78
      end

      expect_save_settings(selector)

      expect(current_settings).to have_attributes(
        "throttle_unauthenticated_#{fragment}_enabled" => true,
        "throttle_unauthenticated_#{fragment}_requests_per_period" => 12,
        "throttle_unauthenticated_#{fragment}_period_in_seconds" => 34,
        "throttle_authenticated_#{fragment}_enabled" => true,
        "throttle_authenticated_#{fragment}_requests_per_period" => 56,
        "throttle_authenticated_#{fragment}_period_in_seconds" => 78
      )
    end
  end

  context 'for Package Registry API rate limits' do
    let(:selector) { 'packages-limits-settings' }
    let(:fragment) { :packages_api }

    include_examples 'regular throttle rate limit settings'
  end

  context 'for Files API rate limits' do
    let(:selector) { 'files-limits-settings' }
    let(:fragment) { :files_api }

    include_examples 'regular throttle rate limit settings'
  end

  context 'for Deprecated API rate limits' do
    let(:selector) { 'deprecated-api-rate-limits-settings' }
    let(:fragment) { :deprecated_api }

    include_examples 'regular throttle rate limit settings'
  end

  it 'changes search rate limits' do
    within_testid('search-limits-settings') do
      fill_in 'Maximum number of requests per minute for an authenticated user', with: 98
      fill_in 'Maximum number of requests per minute for an unauthenticated IP address', with: 76
    end

    expect_save_settings('search-limits-settings')

    expect(current_settings.search_rate_limit).to eq(98)
    expect(current_settings.search_rate_limit_unauthenticated).to eq(76)
  end

  def current_settings
    ApplicationSetting.current_without_cache
  end
end
