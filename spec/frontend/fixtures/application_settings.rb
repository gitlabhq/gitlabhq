# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ApplicationSettingsController, '(JavaScript fixtures)', type: :controller do
  include StubENV
  include JavaScriptFixturesHelpers
  include AdminModeHelper

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let(:project) { create(:project_empty_repo, namespace: namespace, path: 'application-settings') }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    allow(Gitlab::Metrics).to receive(:metrics_folder_present?).and_return(true)
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  render_views

  after do
    remove_repository(project)
  end

  it 'application_settings/accounts_and_limit.html' do
    stub_application_setting(user_default_external: false)

    get :general

    expect(response).to be_successful
  end

  it 'application_settings/usage.html' do
    stub_application_setting(usage_ping_enabled: false)
    stub_application_setting(include_optional_metrics_in_service_ping: false)

    get :metrics_and_profiling

    expect(response).to be_successful
  end
end
