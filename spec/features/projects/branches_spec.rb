require 'rails_helper'

feature 'Branches', feature: true, js: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :master]
    login_as user

    visit namespace_project_branches_path(project.namespace, project)
  end

  it 'should show list of branches' do
    page.within '.all-branches' do
      expect(page).to have_content project.repository.branches.first.name
    end
  end

  it 'should protect a branch' do
    branch_el = first('.all-branches li')
    first('.js-branch-settings-toggle').click

    page.within branch_el do
      click_button 'Protected'
    end

    expect(page).to have_content 'protected'
  end

  it 'should unprotect branch' do
    branch_el = first('.all-branches li')
    first('.js-branch-settings-toggle').click

    page.within branch_el do
      click_button 'Protected'
    end

    expect(page).to have_content 'protected'

    first('.js-branch-settings-toggle').click
    click_link 'Unprotected'

    expect(page).to have_no_content 'protected'
  end

  it 'should allow developers to push' do
    branch_el = first('.all-branches li')
    first('.js-branch-settings-toggle').click
    page.within branch_el do
      click_button 'Protected'
    end
    expect(page).to have_content 'protected'

    first('.js-branch-settings-toggle').click

    branch_el = first('.all-branches li')
    page.within branch_el do
      click_link 'Developers can push'
    end

    expect(page).to have_selector('.js-branch-dev-push.is-active', visible: false)
  end

  it 'should allow branch to be deleted' do
    branch_el = first('.all-branches li')
    branch_name = project.repository.branches.first.name
    first('.js-branch-settings-toggle').click

    page.within branch_el do
      click_link 'Delete branch'
    end
    expect(page).to have_no_content branch_name
  end
end
