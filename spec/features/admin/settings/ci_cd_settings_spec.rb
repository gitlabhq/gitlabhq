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

  it 'changes CI/CD settings' do
    within_testid('ci-cd-settings') do
      check 'Default to Auto DevOps pipeline for all projects'
      fill_in 'application_setting_auto_devops_domain', with: 'domain.com'
      uncheck 'Keep the latest artifacts for all jobs in the latest successful pipelines'
      uncheck 'Enable pipeline suggestion banner'
      uncheck 'Show the migrate from Jenkins banner'
      fill_in 'application_setting_ci_max_includes', with: 200
      fill_in 'application_setting_downstream_pipeline_trigger_limit_per_project_user_sha', with: 500
    end

    expect_save_settings('ci-cd-settings')

    expect(current_settings.auto_devops_enabled?).to be true
    expect(current_settings.auto_devops_domain).to eq('domain.com')
    expect(current_settings.keep_latest_artifact).to be false
    expect(current_settings.suggest_pipeline_enabled).to be false
    expect(current_settings.show_migrate_from_jenkins_banner).to be false
    expect(current_settings.ci_max_includes).to be 200
    expect(current_settings.downstream_pipeline_trigger_limit_per_project_user_sha).to be 500
  end

  it 'changes CI/CD limits', :aggregate_failures do
    within_testid('ci-cd-settings') do
      fill_in 'plan_limits_ci_instance_level_variables', with: 5
      fill_in 'plan_limits_dotenv_size', with: 6
      fill_in 'plan_limits_dotenv_variables', with: 7
      fill_in 'plan_limits_ci_pipeline_size', with: 10
      fill_in 'plan_limits_ci_active_jobs', with: 20
      fill_in 'plan_limits_ci_project_subscriptions', with: 30
      fill_in 'plan_limits_ci_pipeline_schedules', with: 40
      fill_in 'plan_limits_ci_needs_size_limit', with: 50
      fill_in 'plan_limits_ci_registered_group_runners', with: 60
      fill_in 'plan_limits_ci_registered_project_runners', with: 70
    end

    expect_save_settings('ci-cd-settings', button_text: 'Save Default limits')

    limits = default_plan.reload.limits
    expect(limits.ci_instance_level_variables).to eq(5)
    expect(limits.dotenv_size).to eq(6)
    expect(limits.dotenv_variables).to eq(7)
    expect(limits.ci_pipeline_size).to eq(10)
    expect(limits.ci_active_jobs).to eq(20)
    expect(limits.ci_project_subscriptions).to eq(30)
    expect(limits.ci_pipeline_schedules).to eq(40)
    expect(limits.ci_needs_size_limit).to eq(50)
    expect(limits.ci_registered_group_runners).to eq(60)
    expect(limits.ci_registered_project_runners).to eq(70)
  end

  context 'when skipping NuGet package metadata url validation' do
    before do
      allow(Gitlab).to receive(:com?).and_return(false)
      visit ci_cd_admin_application_settings_path
    end

    it 'updates skip NuGet url validation' do
      within_testid('forward-package-requests-form') do
        check 'Skip metadata URL validation for the NuGet package'
      end

      expect_save_settings('forward-package-requests-form')

      expect(current_settings.nuget_skip_metadata_url_validation).to be true
    end
  end

  context 'for Runners' do
    it 'allows admins to control who has access to register runners' do
      expect(current_settings.valid_runner_registrars).to eq(ApplicationSetting::VALID_RUNNER_REGISTRAR_TYPES)

      within_testid('runner-settings') do
        find_all('input[type="checkbox"]').each(&:click)
      end

      expect_save_settings('runner-settings')

      expect(current_settings.valid_runner_registrars).to eq([])
    end

    it 'changes `/jobs/request` rate limits settings' do
      within_testid('runner-settings') do
        fill_in 'Maximum requests per minute to the POST /jobs/request endpoint', with: 0
      end

      expect_save_settings('runner-settings')

      expect(current_settings.runner_jobs_request_api_limit).to eq(0)
    end

    it 'changes `PATCH /jobs/:id/trace` rate limits settings' do
      within_testid('runner-settings') do
        fill_in 'Maximum requests per minute to the PATCH /jobs/:id/trace endpoint', with: 0
      end

      expect_save_settings('runner-settings')

      expect(current_settings.runner_jobs_patch_trace_api_limit).to eq(0)
    end

    it 'changes Runner Jobs rate limits settings' do
      within_testid('runner-settings') do
        fill_in 'Maximum requests per minute to other Runner Jobs API endpoints', with: 0
      end

      expect_save_settings('runner-settings')

      expect(current_settings.runner_jobs_endpoints_api_limit).to eq(0)
    end
  end

  context 'for Job token permissions' do
    it 'allows admin to toggle allowlist enforcement' do
      expect(current_settings.enforce_ci_inbound_job_token_scope_enabled).to be(true)

      within_testid('job-token-permissions-settings') do
        find('input[type="checkbox"]').click
      end

      expect_save_settings('job-token-permissions-settings')

      expect(current_settings.enforce_ci_inbound_job_token_scope_enabled).to be(false)
    end
  end

  context 'for Container Registry', feature_category: :container_registry do
    let(:client_support) { true }
    let(:settings_titles) do
      {
        container_registry_delete_tags_service_timeout: 'Container Registry delete tags service execution timeout',
        container_registry_expiration_policies_worker_capacity: 'Cleanup policy maximum workers running concurrently',
        container_registry_cleanup_tags_service_max_list_size: 'Cleanup policy maximum number of tags to be deleted',
        container_registry_expiration_policies_caching: 'Enable cleanup policy caching'
      }
    end

    before do
      stub_container_registry_config(enabled: true)
      allow(ContainerRegistry::Client).to receive(:supports_tag_delete?).and_return(client_support)
      visit ci_cd_admin_application_settings_path
    end

    %i[
      container_registry_delete_tags_service_timeout
      container_registry_expiration_policies_worker_capacity
      container_registry_cleanup_tags_service_max_list_size
    ].each do |setting|
      context "for container registry setting #{setting}" do
        it 'changes the setting' do
          within_testid('registry-settings') do
            fill_in "application_setting_#{setting}", with: 400
          end

          expect_save_settings('registry-settings')

          expect(current_settings.public_send(setting)).to eq(400)
        end
      end
    end

    context 'for container registry setting container_registry_expiration_policies_caching' do
      it 'updates container_registry_expiration_policies_caching' do
        old_value = current_settings.container_registry_expiration_policies_caching

        within_testid('registry-settings') do
          find('#application_setting_container_registry_expiration_policies_caching').click
        end

        expect_save_settings('registry-settings')

        expect(current_settings.container_registry_expiration_policies_caching).to eq(!old_value)
      end
    end
  end

  def current_settings
    ApplicationSetting.current_without_cache
  end
end
