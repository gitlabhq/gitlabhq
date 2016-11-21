require 'spec_helper'

describe 'Deleted source branch', feature: true, js: true do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }

  before do
    login_as user
    merge_request.project.team << [user, :master]
    merge_request.update!(source_branch: 'this-branch-does-not-exist')
    visit namespace_project_merge_request_path(
      merge_request.project.namespace,
      merge_request.project, merge_request
    )
  end

  it 'shows a message about missing source branch' do
    expect(page).to have_content(
      'Source branch this-branch-does-not-exist does not exist'
    )
  end

  it 'hides Discussion, Commits and Changes tabs' do
    within '.merge-request-details' do
      expect(page).to have_no_content('Discussion')
      expect(page).to have_no_content('Commits')
      expect(page).to have_no_content('Changes')
    end
  end
end
