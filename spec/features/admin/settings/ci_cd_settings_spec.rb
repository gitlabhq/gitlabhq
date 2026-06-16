# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin updates CI/CD settings', :request_store, :enable_admin_mode, feature_category: :continuous_integration do
  include StubENV
  include Features::SettingsHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:default_plan) { create(:default_plan) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
    visit ci_cd_admin_application_settings_path
  end

  it 'changes CI/CD settings', :aggregate_failures do
    within_testid('ci-cd-settings') do
      click_checked_field(s_('CICD|Default to Auto DevOps pipeline for all projects'))
      fill_field_with_new_value(s_('AdminSettings|Auto DevOps domain'), 'domain.com')
      click_checked_field(s_('AdminSettings|Keep the latest artifacts for all jobs in the latest successful pipelines'))
      click_checked_field(s_('AdminSettings|Enable pipeline suggestion banner'))
      click_checked_field(s_('AdminSettings|Show the migrate from Jenkins banner'))
      fill_field_with_new_value(s_('AdminSettings|Maximum includes'), '200')
      fill_field_with_new_value(s_('AdminSettings|Maximum caches per job'), '8')
      fill_field_with_new_value(s_('AdminSettings|Maximum downstream pipeline trigger rate'), '500')

      expect_save_settings

      expect_field_unchecked(s_('CICD|Default to Auto DevOps pipeline for all projects'))
      expect_field_value(s_('AdminSettings|Auto DevOps domain'), 'domain.com')
      expect_field_unchecked(
        s_('AdminSettings|Keep the latest artifacts for all jobs in the latest successful pipelines'))
      expect_field_unchecked(s_('AdminSettings|Enable pipeline suggestion banner'))
      expect_field_unchecked(s_('AdminSettings|Show the migrate from Jenkins banner'))
      expect_field_value(s_('AdminSettings|Maximum includes'), '200')
      expect_field_value(s_('AdminSettings|Maximum caches per job'), '8')
      expect_field_value(s_('AdminSettings|Maximum downstream pipeline trigger rate'), '500')
    end
  end

  it 'changes CI/CD limits', :aggregate_failures do
    within_testid('ci-cd-settings') do
      fill_field_with_new_value(
        s_('AdminSettings|Maximum number of Instance-level CI/CD variables that can be defined'), '5')
      fill_field_with_new_value(s_('AdminSettings|Maximum size of a dotenv artifact in bytes'), '6')
      fill_field_with_new_value(s_('AdminSettings|Maximum number of variables in a dotenv artifact'), '7')
      fill_field_with_new_value(s_('AdminSettings|Maximum number of jobs in a single pipeline'), '10')
      fill_field_with_new_value(s_('AdminSettings|Total number of jobs in currently active pipelines'), '20')
      fill_field_with_new_value(s_('AdminSettings|Maximum number of pipeline subscriptions to and from a project'),
        '30')
      fill_field_with_new_value(s_('AdminSettings|Maximum number of pipeline schedules'), '40')
      fill_field_with_new_value(s_('AdminSettings|Maximum number of needs dependencies that a job can have'), '51')
      fill_field_with_new_value(
        s_('AdminSettings|Maximum number of runners created or active in a group during the past seven days'), '60')
      fill_field_with_new_value(
        s_('AdminSettings|Maximum number of runners created or active in a project during the past seven days'), '70')

      expect_save_settings(button_text: format(s_('AdminSettings|Save %{name} limits'), name: 'Default'))

      expect_field_value(s_('AdminSettings|Maximum number of Instance-level CI/CD variables that can be defined'), '5')
      expect_field_value(s_('AdminSettings|Maximum size of a dotenv artifact in bytes'), '6')
      expect_field_value(s_('AdminSettings|Maximum number of variables in a dotenv artifact'), '7')
      expect_field_value(s_('AdminSettings|Maximum number of jobs in a single pipeline'), '10')
      expect_field_value(s_('AdminSettings|Total number of jobs in currently active pipelines'), '20')
      expect_field_value(s_('AdminSettings|Maximum number of pipeline subscriptions to and from a project'),
        '30')
      expect_field_value(s_('AdminSettings|Maximum number of pipeline schedules'), '40')
      expect_field_value(s_('AdminSettings|Maximum number of needs dependencies that a job can have'), '51')
      expect_field_value(
        s_('AdminSettings|Maximum number of runners created or active in a group during the past seven days'), '60')
      expect_field_value(
        s_('AdminSettings|Maximum number of runners created or active in a project during the past seven days'), '70')
    end
  end

  context 'when skipping NuGet package metadata url validation' do
    before do
      allow(Gitlab).to receive(:com?).and_return(false)
      visit ci_cd_admin_application_settings_path
    end

    it 'updates skip NuGet url validation' do
      within_testid('forward-package-requests-form') do
        click_unchecked_field(s_('PackageRegistry|Skip metadata URL validation for the NuGet package'))

        expect_save_settings

        expect_field_checked(s_('PackageRegistry|Skip metadata URL validation for the NuGet package'))
      end
    end
  end

  context 'for Runners' do
    it 'allows admins to control who has access to register runners', :aggregate_failures do
      within_testid('runner-settings') do
        click_checked_field(format(s_("Runners|Members of the %{type} can create runners"), type: 'project'))
        click_checked_field(format(s_("Runners|Members of the %{type} can create runners"), type: 'group'))

        expect_save_settings

        expect_field_unchecked(format(s_("Runners|Members of the %{type} can create runners"), type: 'project'))
        expect_field_unchecked(format(s_("Runners|Members of the %{type} can create runners"), type: 'group'))
      end
    end

    it 'changes runner rate limits settings', :aggregate_failures do
      within_testid('runner-settings') do
        fill_field_with_new_value(s_('Runners|Maximum requests per minute to the POST /jobs/request endpoint'), '10')
        fill_field_with_new_value(s_('Runners|Maximum requests per minute to the PATCH /jobs/:id/trace endpoint'), '20')
        fill_field_with_new_value(s_('Runners|Maximum requests per minute to other Runner Jobs API endpoints'), '30')

        expect_save_settings

        expect_field_value(s_('Runners|Maximum requests per minute to the POST /jobs/request endpoint'), '10')
        expect_field_value(s_('Runners|Maximum requests per minute to the PATCH /jobs/:id/trace endpoint'), '20')
        expect_field_value(s_('Runners|Maximum requests per minute to other Runner Jobs API endpoints'), '30')
      end
    end
  end

  context 'for Job token permissions' do
    it 'allows admin to toggle allowlist enforcement' do
      within_testid('job-token-permissions-settings') do
        click_checked_field(s_('CICD|Enable and enforce job token allowlist for all projects.'))

        expect_save_settings

        expect_field_unchecked(s_('CICD|Enable and enforce job token allowlist for all projects.'))
      end
    end
  end

  context 'for Container Registry', feature_category: :container_registry do
    let(:client_support) { true }

    before do
      stub_container_registry_config(enabled: true)
      allow(ContainerRegistry::Client).to receive(:supports_tag_delete?).and_return(client_support)
      visit ci_cd_admin_application_settings_path
    end

    it 'changes registry settings', :aggregate_failures do
      within_testid('registry-settings') do
        fill_field_with_new_value(_('Cleanup policy maximum processing time (seconds)'), '100')
        fill_field_with_new_value(_('Cleanup policy maximum workers running concurrently'), '200')
        fill_field_with_new_value(_('Cleanup policy maximum number of tags to be deleted'), '300')
        click_checked_field(_("Enable cleanup policy caching."))

        expect_save_settings

        expect_field_value(_('Cleanup policy maximum processing time (seconds)'), '100')
        expect_field_value(_('Cleanup policy maximum workers running concurrently'), '200')
        expect_field_value(_('Cleanup policy maximum number of tags to be deleted'), '300')
        expect_field_unchecked(_("Enable cleanup policy caching."))
      end
    end
  end
end
