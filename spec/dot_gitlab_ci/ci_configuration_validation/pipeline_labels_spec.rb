# frozen_string_literal: true

require 'spec_helper'
require_relative './shared_context_and_examples'

RSpec.describe 'CI configuration validation - branch pipelines', feature_category: :tooling do
  include ProjectForksHelper
  include CiConfigurationValidationHelper

  include_context 'with simulated pipeline attributes and shared project and user'
  include_context 'with simulated MR pipeline attributes'

  let(:pipeline_project) { gitlab_org_gitlab_project }
  let(:create_pipeline_service) { Ci::CreatePipelineService.new(target_project, user, ref: target_branch) }

  subject(:pipeline) do
    create_pipeline_service
      .execute(
        :push,
        dry_run: true,
        merge_request: merge_request,
        variables_attributes: mr_pipeline_variables_attributes
      ).payload
  end

  context 'when MR labeled with `pipeline:run-all-rspec` is changing app/models/user.rb' do
    let(:mr_labels) { ['pipeline:run-all-rspec'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'rspec-all frontend_fixture 1/7' }

    it_behaves_like 'merge request pipeline'
  end

  context 'when MR labeled with `pipeline:expedite pipeline::expedited` is changing app/models/user.rb' do
    let(:mr_labels) { ['pipeline:expedite', 'pipeline::expedited'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'setup-test-env' }

    it_behaves_like 'merge request pipeline'

    it_behaves_like 'merge train pipeline'
  end

  context 'when MR labeled with `pipeline::tier-1`' do
    let(:mr_labels) { ['pipeline::tier-1'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'pipeline-tier-1' }

    it_behaves_like 'merge request pipeline'
  end

  context 'when MR labeled with `pipeline::tier-2` and `pipeline:mr-approved`' do
    let(:mr_labels) { ['pipeline::tier-2', 'pipeline:mr-approved'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'pipeline-tier-2' }

    it_behaves_like 'merge request pipeline'
  end

  context 'when MR labeled with `pipeline::tier-3` and `pipeline:mr-approved`' do
    let(:mr_labels) { ['pipeline::tier-3', 'pipeline:mr-approved'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'pipeline-tier-3' }

    it_behaves_like 'merge request pipeline'
  end

  context 'when MR labeled with `pipeline:run-as-if-foss` is changing app/models/user.rb' do
    let(:mr_labels) { ['pipeline:run-as-if-foss'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'start-as-if-foss' }

    let(:mr_pipeline_variables_attributes) do
      super() << { key: 'AS_IF_FOSS_TOKEN', value: 'foss token' }
    end

    it_behaves_like 'merge request pipeline'

    it_behaves_like 'merge train pipeline'
  end

  context 'when MR labeled with `pipeline:force-run-as-if-jh` is changing app/models/user.rb' do
    let(:mr_labels) { ['pipeline:force-run-as-if-jh'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'start-as-if-jh' }

    let(:mr_pipeline_variables_attributes) do
      # workflow rule for "include", see .gitlab-ci.yml
      super() << { key: 'CI_PROJECT_URL', value: 'https://gitlab.com/gitlab-org/gitlab' }
    end

    it_behaves_like 'merge request pipeline'

    it_behaves_like 'merge train pipeline'
  end

  context 'when MR labeled with `pipeline:run-as-if-jh` and `pipeline:mr-approved` is changing app/models/user.rb' do
    let(:mr_labels) { ['pipeline:run-as-if-jh', 'pipeline:mr-approved'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'start-as-if-jh' }

    let(:mr_pipeline_variables_attributes) do
      base_attributes = super()
      # workflow rule for "include", see .gitlab-ci.yml
      base_attributes << { key: 'CI_PROJECT_URL', value: 'https://gitlab.com/gitlab-org/gitlab' }
      base_attributes << { key: 'CI_AS_IF_JH_ENABLED', value: 'true' }
    end

    it_behaves_like 'merge request pipeline'

    it_behaves_like 'merge train pipeline'
  end

  context 'when MR labeled with `pipeline:run-in-ruby3_2` is changing app/models/user.rb' do
    let(:mr_labels) { ['pipeline:run-in-ruby3_2'] }
    let(:changed_files) { ['app/models/user.rb'] }
    let(:expected_job_name) { 'e2e-test-pipeline-generate' }

    it_behaves_like 'merge request pipeline'

    it_behaves_like 'merge train pipeline'
  end
end
