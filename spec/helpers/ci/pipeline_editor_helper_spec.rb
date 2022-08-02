# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineEditorHelper do
  let_it_be(:project) { create(:project) }

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

    before do
      allow(helper)
        .to receive(:namespace_project_new_merge_request_path)
        .and_return('/mock/project/-/merge_requests/new')

      allow(helper)
        .to receive(:image_path)
        .with('illustrations/empty-state/empty-dag-md.svg')
        .and_return('illustrations/empty.svg')

      allow(helper)
        .to receive(:image_path)
        .with('illustrations/project-run-CICD-pipelines-sm.svg')
        .and_return('illustrations/validate.svg')
    end

    subject(:pipeline_editor_data) { helper.js_pipeline_editor_data(project) }

    context 'with a project with commits' do
      it 'returns pipeline editor data' do
        expect(pipeline_editor_data).to eq({
          "ci-config-path": project.ci_config_path_or_default,
          "ci-examples-help-page-path" => help_page_path('ci/examples/index'),
          "ci-help-page-path" => help_page_path('ci/index'),
          "ci-lint-path" => project_ci_lint_path(project),
          "default-branch" => project.default_branch_or_main,
          "empty-state-illustration-path" => 'illustrations/empty.svg',
          "initial-branch-name" => nil,
          "includes-help-page-path" => help_page_path('ci/yaml/includes'),
          "lint-help-page-path" => help_page_path('ci/lint', anchor: 'check-cicd-syntax'),
          "lint-unavailable-help-page-path" => help_page_path('ci/pipeline_editor/index', anchor: 'configuration-validation-currently-not-available-message'),
          "needs-help-page-path" => help_page_path('ci/yaml/index', anchor: 'needs'),
          "new-merge-request-path" => '/mock/project/-/merge_requests/new',
          "pipeline_etag" => graphql_etag_pipeline_sha_path(project.commit.sha),
          "pipeline-page-path" => project_pipelines_path(project),
          "project-path" => project.path,
          "project-full-path" => project.full_path,
          "project-namespace" => project.namespace.full_path,
          "runner-help-page-path" => help_page_path('ci/runners/index'),
          "simulate-pipeline-help-page-path" => help_page_path('ci/pipeline_editor/index', anchor: 'simulate-a-cicd-pipeline'),
          "total-branches" => project.repository.branches.length,
          "validate-tab-illustration-path" => 'illustrations/validate.svg',
          "yml-help-page-path" => help_page_path('ci/yaml/index')
        })
      end
    end

    context 'with an empty project' do
      let(:project) { create(:project, :empty_repo) }

      it 'returns pipeline editor data' do
        expect(pipeline_editor_data).to eq({
          "ci-config-path": project.ci_config_path_or_default,
          "ci-examples-help-page-path" => help_page_path('ci/examples/index'),
          "ci-help-page-path" => help_page_path('ci/index'),
          "ci-lint-path" => project_ci_lint_path(project),
          "default-branch" => project.default_branch_or_main,
          "empty-state-illustration-path" => 'illustrations/empty.svg',
          "initial-branch-name" => nil,
          "includes-help-page-path" => help_page_path('ci/yaml/includes'),
          "lint-help-page-path" => help_page_path('ci/lint', anchor: 'check-cicd-syntax'),
          "lint-unavailable-help-page-path" => help_page_path('ci/pipeline_editor/index', anchor: 'configuration-validation-currently-not-available-message'),
          "needs-help-page-path" => help_page_path('ci/yaml/index', anchor: 'needs'),
          "new-merge-request-path" => '/mock/project/-/merge_requests/new',
          "pipeline_etag" => '',
          "pipeline-page-path" => project_pipelines_path(project),
          "project-path" => project.path,
          "project-full-path" => project.full_path,
          "project-namespace" => project.namespace.full_path,
          "runner-help-page-path" => help_page_path('ci/runners/index'),
          "simulate-pipeline-help-page-path" => help_page_path('ci/pipeline_editor/index', anchor: 'simulate-a-cicd-pipeline'),
          "total-branches" => 0,
          "validate-tab-illustration-path" => 'illustrations/validate.svg',
          "yml-help-page-path" => help_page_path('ci/yaml/index')
        })
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

    context 'with a non-default branch name' do
      let(:user) { create(:user) }

      before do
        create_commit('Message', project, user, 'feature')
        controller.params[:branch_name] = 'feature'
      end

      it 'returns correct values' do
        expect(pipeline_editor_data['initial-branch-name']).to eq('feature')
      end
    end
  end
end
