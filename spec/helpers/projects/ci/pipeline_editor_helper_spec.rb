# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::PipelineEditorHelper do
  let_it_be(:project) { create(:project, :public, :repository) }

  describe '#js_pipeline_editor_data' do
    before do
      allow(helper).to receive(:namespace_project_new_merge_request_path).and_return('/mock/project/-/merge_requests/new')
    end

    subject { helper.js_pipeline_editor_data(project) }

    it {
      is_expected.to match({
        "ci-config-path": project.ci_config_path_or_default,
        "commit-sha" => project.commit.sha,
        "default-branch" => project.default_branch,
        "empty-state-illustration-path" => match_asset_path("/assets/illustrations/empty-state/empty-dag-md.svg"),
        "initial-branch-name": nil,
        "lint-help-page-path" => help_page_path('ci/lint', anchor: 'validate-basic-logic-and-syntax'),
        "new-merge-request-path" => '/mock/project/-/merge_requests/new',
        "project-path" => project.path,
        "project-full-path" => project.full_path,
        "project-namespace" => project.namespace.full_path,
        "yml-help-page-path" => help_page_path('ci/yaml/README')
      })
    }
  end
end
