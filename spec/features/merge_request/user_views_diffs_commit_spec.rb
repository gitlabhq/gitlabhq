# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views diff by commit', :js, feature_category: :code_review_workflow do
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  let(:project) { create(:project, :public, :repository) }
  let(:commit_id) { merge_request.diff_head_sha }

  before do
    visit(diffs_project_merge_request_path(project, merge_request, commit_id: commit_id))
  end

  it 'shows full commit description by default' do
    within_testid('commit-content') do
      expect(page).to have_content("Add submodule from gitlab.com")
    end
  end

  it 'shows correct commit metadata' do
    expect(page).to have_content("Viewing commit #{commit_id[..7]}")
    within_testid('diffs-tab') do
      expect(page).to have_content('Changes 2')
    end
    page.within('#diffs') do
      expect(page).to have_content('2 files')
    end
    within_testid('file-tree-container') do
      expect(page).to have_content('Files 2')
    end
  end
end
