# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views rapid diffs', :js, feature_category: :code_review_workflow do
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  let_it_be(:project) { create(:project, :public, :repository) }
  let(:diffs) { merge_request.diffs }

  before do
    stub_feature_flags(rapid_diffs: true)
    visit(diffs_project_merge_request_path(project, merge_request, rapid_diffs: true))

    wait_for_requests
  end

  it_behaves_like 'Rapid Diffs application'
end
