# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobsHelper do
  describe 'job helper functions' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:job) { create(:ci_build, project: project) }

    before do
      helper.instance_variable_set(:@project, project)
      helper.instance_variable_set(:@build, job)
    end

    it 'returns jobs data' do
      expect(helper.jobs_data).to include({
        "endpoint" => "/#{project.full_path}/-/jobs/#{job.id}.json",
        "project_path" => project.full_path,
        "artifact_help_url" => "/help/user/gitlab_com/index.md#gitlab-cicd",
        "deployment_help_url" => "/help/user/project/clusters/deploy_to_cluster.md#troubleshooting",
        "runner_settings_url" => "/#{project.full_path}/-/runners#js-runners-settings",
        "page_path" => "/#{project.full_path}/-/jobs/#{job.id}",
        "build_status" => "pending",
        "build_stage" => "test",
        "log_state" => "",
        "build_options" => {
          build_stage: "test",
          build_status: "pending",
          log_state: "",
          page_path: "/#{project.full_path}/-/jobs/#{job.id}"
        },
        "retry_outdated_job_docs_url" => "/help/ci/pipelines/settings#retry-outdated-jobs"
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
        "waiting_for_resource" => "WAITING_FOR_RESOURCE"
      })
    end
  end
end
