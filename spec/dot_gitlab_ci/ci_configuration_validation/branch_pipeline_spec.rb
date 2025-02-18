# frozen_string_literal: true

require 'spec_helper'
require_relative './shared_context_and_examples'

RSpec.describe 'CI configuration validation - branch pipelines', feature_category: :tooling do
  include ProjectForksHelper
  include CiConfigurationValidationHelper

  include_context 'with simulated pipeline attributes and shared project and user'

  let(:pipeline_project) { gitlab_org_gitlab_project }

  let(:create_pipeline_service) do
    Ci::CreatePipelineService.new(pipeline_project, user, ref: ci_commit_branch)
  end

  let(:content) do
    pipeline_project.repository.blob_at(ci_commit_branch, '.gitlab-ci.yml').data
  end

  subject(:pipeline) do
    trigger_source = ci_pipeline_source.to_sym
    create_pipeline_service
      .execute(trigger_source, dry_run: true, content: content, variables_attributes: variables_attributes)
      .payload
  end

  context 'with branch pipelines' do
    let(:ci_commit_branch) { master_branch }
    let(:variables_attributes) do
      [
        *variables_attributes_base,
        { key: 'CI_COMMIT_BRANCH', value: ci_commit_branch },
        { key: 'CI_COMMIT_REF_NAME', value: ci_commit_branch }
      ]
    end

    context 'with gitlab.com gitlab-org/gitlab master pipeline' do
      context 'with scheduled nightly' do
        let(:ci_pipeline_source) { 'schedule' }
        let(:expected_job_name) { 'db:rollback single-db' }
        let(:variables_attributes) do
          super() << { key: 'SCHEDULE_TYPE', value: 'nightly' }
        end

        it_behaves_like 'default branch pipeline'
      end

      context 'with scheduled maintenance' do
        let(:ci_pipeline_source) { 'schedule' }
        let(:expected_job_name) { 'generate-frontend-fixtures-mapping' }
        let(:variables_attributes) do
          super() << { key: 'SCHEDULE_TYPE', value: 'maintenance' }
        end

        it_behaves_like 'default branch pipeline'
      end
    end

    context 'with gitlab.com gitlab-org/gitlab rails-next branch scheduled pipeline' do
      let(:ci_commit_branch) { 'rails-next' }
      let(:ci_pipeline_source) { 'schedule' }
      let(:expected_job_name) { 'ruby_syntax: [${RUBY_VERSION_DEFAULT}]' }

      before do
        sync_local_files_to_project(
          gitlab_org_gitlab_project,
          user,
          ci_commit_branch,
          files: ci_glob_with_common_file_globs
        )
      end

      it_behaves_like 'default branch pipeline'
    end

    context 'with gitlab.com gitlab-org/gitlab ruby-next branch scheduled pipeline' do
      let(:ci_commit_branch) { 'ruby-next' }
      let(:ci_pipeline_source) { 'schedule' }
      let(:expected_job_name) { 'ruby_syntax: [${RUBY_VERSION_DEFAULT}]' }
      let(:variables_attributes) do
        super() << { key: 'SCHEDULE_TYPE', value: 'nightly' }
      end

      before do
        sync_local_files_to_project(
          gitlab_org_gitlab_project,
          user,
          ci_commit_branch,
          files: ci_glob_with_common_file_globs
        )
      end

      it_behaves_like 'default branch pipeline'
    end

    context 'with gitlab.com gitlab-org/gitlab stable branch pipeline' do
      let(:ci_commit_branch) { '17-1-stable-ee' }
      let(:expected_job_name) { 'run-dev-fixtures-ee' }

      subject(:pipeline) do
        trigger_source = ci_pipeline_source.to_sym
        create_pipeline_service
          .execute(trigger_source, dry_run: true, content: content, variables_attributes: variables_attributes)
          .payload
      end

      before do
        sync_local_files_to_project(
          pipeline_project,
          user,
          ci_commit_branch,
          files: ci_glob_with_common_file_globs
        )
      end

      it_behaves_like 'default branch pipeline'
    end

    context 'with fork project' do
      let(:ci_commit_branch) { master_branch }

      before do
        pipeline_project.add_developer(user)

        sync_local_files_to_project(
          pipeline_project,
          user,
          ci_commit_branch,
          files: ci_glob_with_common_file_globs
        )
      end

      context 'with gitlab.com gitlab-org/security/gitlab project' do
        let_it_be(:sub_group)        { create(:group, parent: group, path: 'security') }
        let_it_be(:security_project) { create(:project, :empty_repo, group: sub_group, path: 'gitlab') }
        let(:ci_project_namespace)   { 'gitlab-org/security' }
        let(:pipeline_project)       { security_project }

        context 'when master pipeline is triggered by push' do
          let(:expected_job_name) { 'static-verification-with-database' }

          it_behaves_like 'default branch pipeline'
        end

        context 'with scheduled master pipeline' do
          let(:ci_pipeline_source) { 'schedule' }
          let(:expected_job_name) { 'update-ruby-gems-coverage-cache-push' }

          it_behaves_like 'default branch pipeline'
        end

        context 'with auto-deploy branch pipeilne' do
          let(:ci_commit_branch)  { '17-3-auto-deploy-2024080508' }
          let(:expected_job_name) { 'build-qa-image' }

          it_behaves_like 'default branch pipeline'
        end

        context 'with stable-ee branch pipeline' do
          let(:ci_commit_branch)  { '17-6-stable-ee' }
          let(:expected_job_name) { 'compile-production-assets' }

          # Test requires syncing CI file, which means the test project's latest commit includes CI file changes
          # This results in `[".frontend:rules:assets-shared", rules]` always evaluates to true.
          # If we don't want to test this specific condition
          # Make sure you comment out `- !reference [".frontend:rules:assets-shared", rules]` everywhere
          # before running this test scenario.
          # Otherwise, this test case always passes.
          it_behaves_like 'default branch pipeline'
        end
      end

      context 'with gitlab.com gitlab-org gitlab-foss project' do
        let_it_be(:foss_project) { create(:project, :empty_repo, group: group, path: 'gitlab-foss') }
        let(:pipeline_project)   { foss_project }

        context 'with master pipeline triggered by push' do
          let(:expected_job_name) { 'db:backup_and_restore single-db' }

          it_behaves_like 'default branch pipeline'
        end

        context 'with scheduled master pipeline' do
          let(:ci_pipeline_source) { 'schedule' }
          let(:expected_job_name) { 'db:backup_and_restore single-db' }

          it_behaves_like 'default branch pipeline'
        end

        # required for building an up-to-date version of GitLab
        # see https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18926
        context 'with build-assets-image' do
          let(:ci_commit_branch) { master_branch }
          let(:expected_job_name) { 'build-assets-image' }

          it_behaves_like 'default branch pipeline'
        end
      end
    end
  end
end
