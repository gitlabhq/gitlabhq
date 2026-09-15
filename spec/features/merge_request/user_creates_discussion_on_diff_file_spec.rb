# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates discussion on diff file', :js, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(diffs_project_merge_request_path(project, merge_request))
  end

  it 'creates discussion on diff file' do
    within(first('diff-file')) do
      find('[data-testid="comment-files-button"]:not([disabled])').click

      find_by_testid('reply-field').set('Test comment')
      click_button 'Add comment now'

      expect(page).to have_selector('[data-testid="noteable-note-container"]', text: 'Test comment')
    end
  end
end
