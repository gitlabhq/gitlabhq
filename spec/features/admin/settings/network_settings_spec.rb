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

  it 'changes Outbound requests settings', :aggregate_failures do
    within_testid('outbound-requests-content') do
      click_unchecked_field(s_('OutboundRequests|Allow requests to the local network from webhooks and integrations'))
      click_checked_field(s_('OutboundRequests|Allow requests to the local network from system hooks'))
      click_checked_field(s_('OutboundRequests|Enforce DNS-rebinding attack protection'))

      expect_save_settings

      expect_field_checked(s_('OutboundRequests|Allow requests to the local network from webhooks and integrations'))
      expect_field_unchecked(s_('OutboundRequests|Allow requests to the local network from system hooks'))
      expect_field_unchecked(s_('OutboundRequests|Enforce DNS-rebinding attack protection'))
    end
  end

  it 'changes User and IP rate limits settings', :aggregate_failures do
    within_testid('ip-limits-content') do
      click_unchecked_field(_('Enable unauthenticated API request rate limit'))
      fill_field_with_new_value(_('Maximum unauthenticated API requests per rate limit period per IP'), '100')
      fill_field_with_new_value(_('Unauthenticated API rate limit period in seconds'), '200')

      click_unchecked_field(_('Enable unauthenticated web request rate limit'))
      fill_field_with_new_value(_('Maximum unauthenticated web requests per rate limit period per IP'), '300')
      fill_field_with_new_value(_('Unauthenticated web rate limit period in seconds'), '400')

      click_unchecked_field(_('Enable authenticated API request rate limit'))
      fill_field_with_new_value(_('Maximum authenticated API requests per rate limit period per user'), '500')
      fill_field_with_new_value(_('Authenticated API rate limit period in seconds'), '600')

      click_unchecked_field(_('Enable authenticated web request rate limit'))
      fill_field_with_new_value(_('Maximum authenticated web requests per rate limit period per user'), '700')
      fill_field_with_new_value(_('Authenticated web rate limit period in seconds'), '800')

      fill_field_with_new_value("Maximum authenticated requests to project/:id/jobs per minute", '1000')

      fill_field_with_new_value(_('Plain-text response to send to clients that hit a rate limit'), 'Custom message')

      expect_save_settings

      expect_field_checked(_('Enable unauthenticated API request rate limit'))
      expect_field_value(_('Maximum unauthenticated API requests per rate limit period per IP'), '100')
      expect_field_value(_('Unauthenticated API rate limit period in seconds'), '200')

      expect_field_checked(_('Enable unauthenticated web request rate limit'))
      expect_field_value(_('Maximum unauthenticated web requests per rate limit period per IP'), '300')
      expect_field_value(_('Unauthenticated web rate limit period in seconds'), '400')

      expect_field_checked(_('Enable authenticated API request rate limit'))
      expect_field_value(_('Maximum authenticated API requests per rate limit period per user'), '500')
      expect_field_value(_('Authenticated API rate limit period in seconds'), '600')

      expect_field_checked(_('Enable authenticated web request rate limit'))
      expect_field_value(_('Maximum authenticated web requests per rate limit period per user'), '700')
      expect_field_value(_('Authenticated web rate limit period in seconds'), '800')

      expect_field_value("Maximum authenticated requests to project/:id/jobs per minute", '1000')

      expect_field_value(_('Plain-text response to send to clients that hit a rate limit'), 'Custom message')
    end
  end

  it 'changes authenticated Git HTTP rate limits settings', :aggregate_failures do
    within_testid('git-http-limits-settings') do
      click_unchecked_field(_('Enable authenticated Git HTTP request rate limit'))
      fill_field_with_new_value(
        _('Maximum authenticated Git HTTP requests per period per user'),
        (ApplicationSetting::DEFAULT_AUTHENTICATED_GIT_HTTP_LIMIT + 1).to_s
      )
      fill_field_with_new_value(
        _('Authenticated Git HTTP rate limit period in seconds'),
        (ApplicationSetting::DEFAULT_AUTHENTICATED_GIT_HTTP_PERIOD + 2).to_s
      )

      expect_save_settings

      expect_field_checked(_('Enable authenticated Git HTTP request rate limit'))
      expect_field_value(
        _('Maximum authenticated Git HTTP requests per period per user'),
        (ApplicationSetting::DEFAULT_AUTHENTICATED_GIT_HTTP_LIMIT + 1).to_s
      )
      expect_field_value(
        _('Authenticated Git HTTP rate limit period in seconds'),
        (ApplicationSetting::DEFAULT_AUTHENTICATED_GIT_HTTP_PERIOD + 2).to_s
      )
    end
  end

  it 'changes Issues rate limits settings' do
    within_testid('issue-limits-settings') do
      fill_field_with_new_value(_('Maximum number of requests per minute'), '0')

      expect_save_settings

      expect_field_value(_('Maximum number of requests per minute'), '0')
    end
  end

  it 'changes Pipelines rate limits settings', :aggregate_failures do
    within_testid('pipeline-limits-settings') do
      fill_field_with_new_value(_('Maximum number of requests per project, sha and user. Resets after 1 minute.'), '10')
      fill_field_with_new_value(_('Maximum number of requests for a user. Resets after 1 minute.'), '100')

      expect_save_settings

      expect_field_value(_('Maximum number of requests per project, sha and user. Resets after 1 minute.'), '10')
      expect_field_value(_('Maximum number of requests for a user. Resets after 1 minute.'), '100')
    end
  end

  it 'changes gitlab shell operation limits settings' do
    within_testid('gitlab-shell-operation-limits') do
      fill_field_with_new_value(s_('ShellOperations|Maximum number of Git operations per minute'), '100')

      expect_save_settings

      expect_field_value(s_('ShellOperations|Maximum number of Git operations per minute'), '100')
    end
  end

  it 'changes users API rate limits settings', :aggregate_failures do
    within_testid('users-api-limits-settings') do
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user'),
          api_name: 'GET /users/:id', timeframe: '10 minutes'), '1')
      fill_in _('Excluded users'), with: 'someone, someone_else'
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/followers', timeframe: 'minute'), '2')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/following', timeframe: 'minute'), '3')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/status', timeframe: 'minute'), '4')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/keys', timeframe: 'minute'), '5')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/keys/:key_id', timeframe: 'minute'), '6')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/gpg_keys', timeframe: 'minute'), '7')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/gpg_keys/:key_id', timeframe: 'minute'), '8')

      expect_save_settings

      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user'),
          api_name: 'GET /users/:id', timeframe: '10 minutes'), '1')
      expect_field_value(_('Excluded users'), "someone\nsomeone_else")
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/followers', timeframe: 'minute'), '2')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/following', timeframe: 'minute'), '3')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/status', timeframe: 'minute'), '4')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/keys', timeframe: 'minute'), '5')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/keys/:key_id', timeframe: 'minute'), '6')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/gpg_keys', timeframe: 'minute'), '7')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/gpg_keys/:key_id', timeframe: 'minute'), '8')
    end
  end

  it 'changes organizations API rate limits settings' do
    within_testid('organizations-api-limits-settings') do
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user'),
          api_name: 'POST /organizations', timeframe: 'minute'), '1234')

      expect_save_settings

      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user'),
          api_name: 'POST /organizations', timeframe: 'minute'), '1234')
    end
  end

  it 'changes groups API rate limits settings', :aggregate_failures do
    within_testid('groups-api-limits-settings') do
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups', timeframe: 'minute'), '1')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id', timeframe: 'minute'), '2')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id/projects', timeframe: 'minute'), '3')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id/groups/shared', timeframe: 'minute'), '4')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id/invited_groups', timeframe: 'minute'), '5')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name1} and %{api_name2} APIs per %{timeframe} per user or IP address'),
          api_name1: 'POST /groups/:id/archive', api_name2: 'POST /groups/:id/unarchive', timeframe: 'minute'), '6')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user'),
          api_name: 'POST /groups', timeframe: 'day'), '7')

      expect_save_settings

      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups', timeframe: 'minute'), '1')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id', timeframe: 'minute'), '2')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id/projects', timeframe: 'minute'), '3')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id/groups/shared', timeframe: 'minute'), '4')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id/invited_groups', timeframe: 'minute'), '5')
      expect_field_value(
        format(_('Maximum requests to the %{api_name1} and %{api_name2} APIs per %{timeframe} per user or IP address'),
          api_name1: 'POST /groups/:id/archive', api_name2: 'POST /groups/:id/unarchive', timeframe: 'minute'), '6')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user'),
          api_name: 'POST /groups', timeframe: 'day'), '7')
    end
  end

  it 'changes projects API rate limits settings', :aggregate_failures do
    within_testid('projects-api-limits-settings') do
      fill_field_with_new_value(
        format(
          _('Maximum requests to the %{api_name} API per %{timeframe} per IP address for unauthenticated requests'),
          api_name: 'GET /projects', timeframe: '10 minutes'), '1')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user for authenticated requests'),
          api_name: 'GET /projects', timeframe: '10 minutes'), '2')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /projects/:id', timeframe: 'minute'), '3')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /projects/:id/members/all', timeframe: 'minute'), '4')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /projects/:id/invited_groups', timeframe: 'minute'), '5')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/projects', timeframe: 'minute'), '6')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/contributed_projects', timeframe: 'minute'), '7')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/starred_projects', timeframe: 'minute'), '8')
      fill_field_with_new_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user'),
          api_name: 'POST /projects', timeframe: 'day'), '9')

      expect_save_settings

      expect_field_value(
        format(
          _('Maximum requests to the %{api_name} API per %{timeframe} per IP address for unauthenticated requests'),
          api_name: 'GET /projects', timeframe: '10 minutes'), '1')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user for authenticated requests'),
          api_name: 'GET /projects', timeframe: '10 minutes'), '2')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /projects/:id', timeframe: 'minute'), '3')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /projects/:id/members/all', timeframe: 'minute'), '4')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /projects/:id/invited_groups', timeframe: 'minute'), '5')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/projects', timeframe: 'minute'), '6')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/contributed_projects', timeframe: 'minute'), '7')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/starred_projects', timeframe: 'minute'), '8')
      expect_field_value(
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user'),
          api_name: 'POST /projects', timeframe: 'day'), '9')
    end
  end

  describe 'throttle rate limit settings' do
    using RSpec::Parameterized::TableSyntax

    where(:description, :selector) do
      'Package Registry' | 'packages-limits-settings'
      'Files'            | 'files-limits-settings'
      'Deprecated'       | 'deprecated-api-rate-limits-settings'
    end

    with_them do
      it "changes #{description} API rate limits settings", :aggregate_failures do
        within_testid(selector) do
          click_unchecked_field(_('Enable unauthenticated API request rate limit'))
          fill_field_with_new_value(_('Maximum unauthenticated API requests per rate limit period per IP'), '12')
          fill_field_with_new_value(_('Unauthenticated API rate limit period in seconds'), '34')

          click_unchecked_field(_('Enable authenticated API request rate limit'))
          fill_field_with_new_value(_('Maximum authenticated API requests per rate limit period per user'), '56')
          fill_field_with_new_value(_('Authenticated API rate limit period in seconds'), '78')

          expect_save_settings

          expect_field_checked(_('Enable unauthenticated API request rate limit'))
          expect_field_value(_('Maximum unauthenticated API requests per rate limit period per IP'), '12')
          expect_field_value(_('Unauthenticated API rate limit period in seconds'), '34')

          expect_field_checked(_('Enable authenticated API request rate limit'))
          expect_field_value(_('Maximum authenticated API requests per rate limit period per user'), '56')
          expect_field_value(_('Authenticated API rate limit period in seconds'), '78')
        end
      end
    end
  end

  it 'changes search rate limits', :aggregate_failures do
    within_testid('search-limits-settings') do
      fill_field_with_new_value(_('Maximum number of requests per minute for an authenticated user'), '98')
      fill_field_with_new_value(_('Maximum number of requests per minute for an unauthenticated IP address'), '76')

      expect_save_settings

      expect_field_value(_('Maximum number of requests per minute for an authenticated user'), '98')
      expect_field_value(_('Maximum number of requests per minute for an unauthenticated IP address'), '76')
    end
  end
end
