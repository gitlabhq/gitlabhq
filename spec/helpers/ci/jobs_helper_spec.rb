# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobsHelper, feature_category: :continuous_integration do
  describe 'job helper functions' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:job) { create(:ci_build, project: project) }
    let_it_be(:user) { create(:user) }

    before do
      helper.instance_variable_set(:@project, project)
      helper.instance_variable_set(:@build, job)

      allow(helper)
      .to receive(:current_user)
      .and_return(user)
    end

    it 'returns jobs data' do
      expect(helper.jobs_data(project, job)).to include({
        "endpoint" => "/#{project.full_path}/-/jobs/#{job.id}.json",
        "page_path" => "/#{project.full_path}/-/jobs/#{job.id}",
        "project_path" => project.full_path,
        "artifact_help_url" => "/help/user/gitlab_com/index.md#gitlab-cicd",
        "deployment_help_url" => "/help/user/project/clusters/deploy_to_cluster.md#troubleshooting",
        "runner_settings_url" => "/#{project.full_path}/-/runners#js-runners-settings",
        "build_status" => "pending",
        "build_stage" => "test",
        "retry_outdated_job_docs_url" => "/help/ci/pipelines/settings#retry-outdated-jobs",
        "test_report_summary_url" => "/#{project.full_path}/-/jobs/#{job.id}/test_report_summary.json",
        "pipeline_test_report_url" => "/#{project.full_path}/-/pipelines/#{job.pipeline.id}/test_report"
      })
    end

    it 'returns job statuses' do
      expect(helper.job_statuses).to eq({
        "canceled" => "CANCELED",
        "created" => "CREATED",
        "failed" => "FAILED",
        "manual" => "MANUAL",
        "pending" => "PENDING",
        "preparing" => "PREPARING",
        "running" => "RUNNING",
        "scheduled" => "SCHEDULED",
        "skipped" => "SKIPPED",
        "success" => "SUCCESS",
        "waiting_for_callback" => "WAITING_FOR_CALLBACK",
        "waiting_for_resource" => "WAITING_FOR_RESOURCE"
      })
    end
  end
end
