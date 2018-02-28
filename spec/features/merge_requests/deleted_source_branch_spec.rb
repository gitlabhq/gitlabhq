require 'spec_helper'

# This test serves as a regression test for a bug that caused an error
# message to be shown by JavaScript when the source branch was deleted.
# Please do not remove "js: true".
describe 'Deleted source branch', js: true do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }

  before do
    sign_in user
    merge_request.project.team << [user, :master]
    merge_request.update!(source_branch: 'this-branch-does-not-exist')
    visit project_merge_request_path(merge_request.project, merge_request)
  end

  it 'shows a message about missing source branch' do
    expect(page).to have_content(
      'Source branch does not exist.'
    )
  end

  it 'still contains Discussion, Commits and Changes tabs' do
    within '.merge-request-details' do
      expect(page).to have_content('Discussion')
      expect(page).to have_content('Commits')
      expect(page).to have_content('Changes')
    end

    click_on 'Changes'
    wait_for_requests

    expect(page).to have_selector('.diffs.tab-pane .nothing-here-block')
    expect(page).to have_content('Source branch does not exist.')
  end
end
