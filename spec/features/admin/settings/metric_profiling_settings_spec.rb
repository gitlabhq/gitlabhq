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
      click_checked_field(_('Enable GitLab Prometheus metrics endpoint'))

      expect_save_settings

      expect_field_unchecked(_('Enable GitLab Prometheus metrics endpoint'))
    end
  end

  it 'change Performance bar settings', :aggregate_failures do
    group = create(:group)

    within_testid('performance-bar-settings-content') do
      click_unchecked_field _('Allow non-administrators access to the performance bar')
      fill_field_with_new_value _('Allow access to members of the following group'), group.path.to_s

      expect_save_settings(refresh: true)

      expect_field_checked _('Allow non-administrators access to the performance bar')
      expect_field_value(_('Allow access to members of the following group'), group.path.to_s)
    end

    within_testid('performance-bar-settings-content') do
      click_checked_field _('Allow non-administrators access to the performance bar')

      expect_save_settings

      expect_field_unchecked _('Allow non-administrators access to the performance bar')
    end

    expect_field_value(_('Allow access to members of the following group'), nil)
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
end
