# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineEditorHelper, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  describe 'can_view_pipeline_editor?' do
    subject { helper.can_view_pipeline_editor?(project) }

    it 'user can view editor if they can collaborate' do
      allow(helper).to receive(:can_collaborate_with_project?).and_return(true)

      expect(subject).to be true
    end

    it 'user can not view editor if they cannot collaborate' do
      allow(helper).to receive(:can_collaborate_with_project?).and_return(false)

      expect(subject).to be false
    end
  end

  describe '#js_pipeline_editor_data' do
    let(:project) { create(:project, :repository) }
    let(:default_helper_data) do
      {
        "ci-catalog-path" => explore_catalog_index_path,
        "ci-config-path": project.ci_config_path_or_default,
        "ci-examples-help-page-path" => help_page_path('ci/examples/_index.md'),
        "ci-help-page-path" => help_page_path('ci/_index.md'),
        "ci-lint-path" => project_ci_lint_path(project),
        "ci-troubleshooting-path" => help_page_path('ci/debugging.md', anchor: 'job-configuration-issues'),
        "default-branch" => project.default_branch_or_main,
        "empty-state-illustration-path" => 'illustrations/empty.svg',
        "initial-branch-name" => nil,
        "includes-help-page-path" => help_page_path('ci/yaml/includes.md'),
        "lint-help-page-path" => help_page_path('ci/yaml/lint.md', anchor: 'check-cicd-syntax'),
        "needs-help-page-path" => help_page_path('ci/yaml/_index.md', anchor: 'needs'),
        "new-merge-request-path" => '/mock/project/-/merge_requests/new',
        "pipeline-page-path" => project_pipelines_path(project),
        "project-path" => project.path,
        "project-full-path" => project.full_path,
        "project-namespace" => project.namespace.full_path,
        "simulate-pipeline-help-page-path" => help_page_path('ci/pipeline_editor/_index.md', anchor: 'simulate-a-cicd-pipeline'),
        "uses-external-config" => 'false',
        "validate-tab-illustration-path" => 'illustrations/validate.svg',
        "yml-help-page-path" => help_page_path('ci/yaml/_index.md')
      }
    end

    before do
      allow(helper)
        .to receive(:namespace_project_new_merge_request_path)
        .and_return('/mock/project/-/merge_requests/new')

      allow(helper)
        .to receive(:image_path)
        .with('illustrations/empty-state/empty-pipeline-md.svg')
        .and_return('illustrations/empty.svg')

      allow(helper)
        .to receive(:image_path)
        .with('illustrations/empty-state/empty-devops-md.svg')
        .and_return('illustrations/validate.svg')

      allow(helper)
        .to receive(:current_user)
        .and_return(user)
    end

    subject(:pipeline_editor_data) { helper.js_pipeline_editor_data(project) }

    context 'with a project with commits' do
      it 'returns pipeline editor data' do
        expect(pipeline_editor_data).to include(default_helper_data.merge({
          "pipeline_etag" => graphql_etag_pipeline_sha_path(project.commit.sha),
          "total-branches" => project.repository.branches.length
        }))
      end
    end

    context 'with an empty project' do
      let(:project) { create(:project, :empty_repo) }

      it 'returns pipeline editor data' do
        expect(pipeline_editor_data).to include(default_helper_data.merge({
          "pipeline_etag" => '',
          "total-branches" => 0
        }))
      end
    end

    context 'with a project with no repository' do
      let(:project) { create(:project) }

      it 'returns pipeline editor data' do
        expect(pipeline_editor_data).to include({
          "pipeline_etag" => '',
          "total-branches" => 0
        })
      end
    end

    context 'with a remote CI config' do
      before do
        create(:commit, project: project)
        project.ci_config_path = 'http://example.com/path/to/ci/config.yml'
      end

      it 'returns true for uses-external-config in pipeline editor data' do
        expect(pipeline_editor_data['uses-external-config']).to eq('true')
      end
    end

    context 'with a CI config from an external project' do
      before do
        create(:commit, project: project)
        project.ci_config_path = '.gitlab-ci.yml@group/project'
      end

      it 'returns true for uses-external-config in pipeline editor data' do
        expect(pipeline_editor_data['uses-external-config']).to eq('true')
      end
    end

    context 'with a non-default branch name' do
      let(:user) { create(:user) }

      before do
        project.repository.commit_files(
          user,
          branch_name: 'feature',
          message: 'Message',
          actions: [{ action: :create, file_path: 'a/new.file', content: 'This is a new file' }]
        )
        controller.params[:branch_name] = 'feature'
      end

      it 'returns correct values' do
        expect(pipeline_editor_data['initial-branch-name']).to eq('feature')
      end
    end
  end
end
