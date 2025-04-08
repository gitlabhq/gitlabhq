# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views diffs', :js, feature_category: :code_review_workflow do
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  let_it_be(:project) { create(:project, :public, :repository) }
  let(:view) { 'inline' }
  let(:last_commit_text) { 'Subproject commit 79bceae69cb5750d6567b223597999bfa91cb3b9' }

  before do
    stub_feature_flags(rapid_diffs: true)
    visit(diffs_project_merge_request_path(project, merge_request, view: view, rapid_diffs: true))

    wait_for_requests
  end

  it 'shows the last diff file' do
    expect(page).to have_selector('[data-testid="rd-diff-file"]', text: last_commit_text)
  end
end
