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

  context "when unlabeled MR is changing GITALY_SERVER_VERSION" do
    let(:changed_files) { ['GITALY_SERVER_VERSION'] }
    let(:expected_job_name) { 'eslint' }

    it_behaves_like 'merge request pipeline'

    it_behaves_like 'merge train pipeline'
  end

  context "when unlabeled MR is changing docs only" do
    let(:changed_files) { ['doc/tutorials/index.md'] }
    let(:expected_job_name) { 'eslint-docs' }

    it_behaves_like 'merge request pipeline'

    it_behaves_like 'merge train pipeline'
  end

  context 'when MR is created from "release-tools/update-gitaly" source branch' do
    let(:source_branch) { 'release-tools/update-gitaly' }
    let(:changed_files) { ['GITALY_SERVER_VERSION'] }
    let(:expected_job_name) { 'update-gitaly-binaries-cache' }

    it_behaves_like 'merge request pipeline'
  end

  context 'when MR targeting a stable branch is changing app/models/user.rb' do
    let(:target_branch)     { '16-10-stable-ee' }
    let(:changed_files)     { ['app/models/user.rb'] }
    let(:expected_job_name) { 'rspec-all frontend_fixture 1/7' }

    before do
      sync_local_files_to_project(
        target_project,
        user,
        target_branch,
        files: ci_glob
      )
    end

    after do
      target_project.repository.delete_branch(target_branch)
    end

    it_behaves_like 'merge request pipeline'

    it_behaves_like 'merge train pipeline'
  end

  context 'with fork project MRs' do
    let_it_be(:fork_project_mr_source) { fork_project(gitlab_org_gitlab_project, user, repository: true) }
    let(:source_project)    { fork_project_mr_source }
    let(:target_project)    { gitlab_org_gitlab_project }

    context 'when MR is created from a fork project master branch' do
      let(:source_branch)     { master_branch }
      let(:target_branch)     { master_branch }
      let(:changed_files)     { ['package.json'] }
      let(:expected_job_name) { 'rspec-all frontend_fixture 1/7' }

      context 'when running MR pipeline in the context of the fork project' do
        let(:ci_project_namespace) { fork_project_mr_source.namespace.full_path }
        let(:ci_project_path)      { fork_project_mr_source.full_path }
        let(:ci_project_name)      { fork_project_mr_source.name }

        it_behaves_like 'merge request pipeline'
      end

      context 'when running MR pipeline in the context of canonical project' do
        it_behaves_like 'merge request pipeline'
      end

      it_behaves_like 'merge train pipeline'
    end

    context 'when MR is created from a fork project feature branch' do
      let(:source_branch)     { "feature_branch_ci_#{SecureRandom.uuid}" }
      let(:target_branch)     { master_branch }
      let(:changed_files)     { ['package.json'] }
      let(:expected_job_name) { 'rspec-all frontend_fixture 1/7' }

      context 'when running MR pipeline in the context of the fork project' do
        let(:ci_project_namespace) { fork_project_mr_source.namespace.full_path }
        let(:ci_project_path)      { fork_project_mr_source.full_path }
        let(:ci_project_name)      { fork_project_mr_source.name }

        it_behaves_like 'merge request pipeline'
      end

      context 'when running MR pipeline in the context of canonical project' do
        it_behaves_like 'merge request pipeline'
      end

      it_behaves_like 'merge train pipeline'
    end
  end
end
