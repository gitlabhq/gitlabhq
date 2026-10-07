# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views diffs file-by-file', :js, feature_category: :code_review_workflow do
  let(:merge_request) do
    create(:merge_request, source_branch: 'squash-large-files', source_project: project, target_project: project)
  end

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user, view_diffs_file_by_file: true) }

  before do
    project.add_developer(user)

    sign_in(user)

    visit(diffs_project_merge_request_path(project, merge_request, file_path: 'large_diff.md'))
  end

  it 'shows diffs file-by-file' do
    page.within('#diffs') do
      expect(page).to have_selector('diff-file header h2', text: 'large_diff.md')
      expect(page).not_to have_content('This diff is collapsed')

      within_testid('file-by-file-navigation') { click_button('Next') }

      expect(page).to have_selector('diff-file header h2', text: 'large_diff_renamed.md')
      expect(page).not_to have_content('This diff is collapsed')
    end
  end
end
