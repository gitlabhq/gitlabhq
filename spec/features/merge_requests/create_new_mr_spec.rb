require 'spec_helper'

feature 'Create New Merge Request', feature: true, js: true do
  include WaitForAjax

  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  before do
    project.team << [user, :master]

    login_as user
  end

  it 'generates a diff for an orphaned branch' do
    visit namespace_project_merge_requests_path(project.namespace, project)

    click_link 'New Merge Request'
    expect(page).to have_content('Source branch')
    expect(page).to have_content('Target branch')

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

  it 'allows to change the diff view' do
    visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { target_branch: 'master', source_branch: 'fix' })

    click_link 'Changes'

    expect(page).to have_css('a.btn.active', text: 'Inline')
    expect(page).not_to have_css('a.btn.active', text: 'Side-by-side')

    click_link 'Side-by-side'

    expect(page).to have_css('a.btn.active', text: 'Side-by-side')
    expect(page).not_to have_css('a.btn.active', text: 'Inline')
  end
end
