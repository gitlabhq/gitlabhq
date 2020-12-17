# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views diff by commit', :js do
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  let(:project) { create(:project, :public, :repository) }

  before do
    visit(diffs_project_merge_request_path(project, merge_request, commit_id: merge_request.diff_head_sha))
  end

  it 'shows full commit description by default' do
    expect(page).to have_selector('.commit-row-description', visible: true)
  end
end
