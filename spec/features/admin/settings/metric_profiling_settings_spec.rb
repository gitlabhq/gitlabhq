# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin updates metrics and profiling settings', :request_store, :enable_admin_mode,
  feature_category: :observability do
  include StubENV
  include UsageDataHelpers
  include Features::SettingsHelpers

  let_it_be(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
    visit metrics_and_profiling_admin_application_settings_path
  end

  it 'change Prometheus settings' do
    within_testid('prometheus-settings') do
      check 'Enable GitLab Prometheus metrics endpoint'
    end

    expect_save_settings('prometheus-settings')

    expect(current_settings.prometheus_metrics_enabled?).to be true
  end

  it 'change Performance bar settings' do
    group = create(:group)

    within_testid('performance-bar-settings-content') do
      check 'Allow non-administrators access to the performance bar'
      fill_in 'Allow access to members of the following group', with: group.path
    end

    expect_save_settings('performance-bar-settings-content', refresh: true)

    expect(find_field('Allow non-administrators access to the performance bar')).to be_checked
    expect(find_field('Allow access to members of the following group').value).to eq group.path

    within_testid('performance-bar-settings-content') do
      uncheck 'Allow non-administrators access to the performance bar'
    end

    expect_save_settings('performance-bar-settings-content')

    expect(find_field('Allow non-administrators access to the performance bar')).not_to be_checked
    expect(find_field('Allow access to members of the following group').value).to be_nil
  end

  context 'for service usage data', :with_license do
    before do
      stub_usage_data_connections
      stub_database_flavor_check
    end

    context 'when service data cached' do
      before_all do
        create(:raw_usage_data)
      end

      it 'loads usage ping payload on click', :js,
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/449030' do
        expected_payload_content = /(?=.*"test")/m

        expect(page).not_to have_content expected_payload_content

        click_button('Preview payload')

        wait_for_requests

        expect(page).to have_button 'Hide payload'
        expect(page).to have_content expected_payload_content
      end

      it 'generates usage ping payload on button click', :js,
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/449030' do
        expect_next_instance_of(Admin::ApplicationSettingsController) do |instance|
          expect(instance).to receive(:usage_data).and_call_original
        end

        click_button('Download payload')

        wait_for_requests
      end
    end

    context 'when service data not cached' do
      it 'renders missing cache information' do
        expect(page).to have_text('Service Ping payload not found in the application cache')
      end
    end
  end

  def current_settings
    ApplicationSetting.current_without_cache
  end
end
