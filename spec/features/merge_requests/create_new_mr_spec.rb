require 'spec_helper'

feature 'Create New Merge Request', feature: true, js: true do
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

  context 'when approvals are disabled for the target project' do
    it 'does not show approval settings' do
      visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { source_branch: 'feature_conflict' })

      expect(page).not_to have_content('Approvers')
    end
  end

  context 'when approvals are enabled for the target project' do
    before do
      project.update_attributes(approvals_before_merge: 1)

      visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { source_branch: 'feature_conflict' })
    end

    it 'shows approval settings' do
      expect(page).to have_content('Approvers')
    end

    context 'saving the MR' do
      it 'shows the saved MR' do
        fill_in 'merge_request_title', with: 'Test'
        click_button 'Submit merge request'

        expect(page).to have_link('Close merge request')
      end
    end
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

    within '.merge-request' do
      expect(page).not_to have_css('a.btn.active', text: 'Inline')
      expect(page).to have_css('a.btn.active', text: 'Side-by-side')
    end
  end

  it 'does not allow non-existing branches' do
    visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { target_branch: 'non-exist-target', source_branch: 'non-exist-source' })

    expect(page).to have_content('The form contains the following errors')
    expect(page).to have_content('Source branch "non-exist-source" does not exist')
    expect(page).to have_content('Target branch "non-exist-target" does not exist')
  end

  context 'when a branch contains commits that both delete and add the same image' do
    it 'renders the diff successfully' do
      visit new_namespace_project_merge_request_path(project.namespace, project, merge_request: { target_branch: 'master', source_branch: 'deleted-image-test' })

      click_link "Changes"

      expect(page).to have_content "6049019_460s.jpg"
    end
  end
end
