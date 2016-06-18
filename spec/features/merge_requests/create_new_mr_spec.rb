require 'spec_helper'

feature 'Create New Merge Request', feature: true, js: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  before do
    project.team << [user, :master]

    login_as user
    visit namespace_project_merge_requests_path(project.namespace, project)
  end

  it 'generates a diff for an orphaned branch' do
    click_link 'New Merge Request'

    first('.js-source-branch').click
    first('.dropdown-source-branch .dropdown-content a', text: 'orphaned-branch').click

    click_button "Compare branches"
    click_link "Changes"

    expect(page).to have_content "README.md"
    expect(page).to have_content "wm.png"

    fill_in "merge_request_title", with: "Orphaned MR test"
    click_button "Submit merge request"

    click_link "Check out branch"

    expect(page).to have_content 'git checkout -b orphaned-branch origin/orphaned-branch'
  end

  context 'when target project cannot be viewed by the current user' do
    it 'does not leak the private project name & namespace' do
      private_project = create(:project, :private)

      visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { target_project_id: private_project.id })

      expect(page).not_to have_content private_project.to_reference
    end
  end
end
