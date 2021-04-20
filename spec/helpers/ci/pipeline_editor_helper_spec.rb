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
        .and_return('foo')
    end

    subject(:pipeline_editor_data) { helper.js_pipeline_editor_data(project) }

    it 'returns pipeline editor data' do
      expect(pipeline_editor_data).to eq({
        "ci-config-path": project.ci_config_path_or_default,
        "commit-sha" => project.commit.sha,
        "default-branch" => project.default_branch,
        "empty-state-illustration-path" => 'foo',
        "initial-branch-name": nil,
        "lint-help-page-path" => help_page_path('ci/lint', anchor: 'validate-basic-logic-and-syntax'),
        "new-merge-request-path" => '/mock/project/-/merge_requests/new',
        "project-path" => project.path,
        "project-full-path" => project.full_path,
        "project-namespace" => project.namespace.full_path,
        "yml-help-page-path" => help_page_path('ci/yaml/README')
      })
    end
  end
end
