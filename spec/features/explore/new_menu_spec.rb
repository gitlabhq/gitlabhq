require 'spec_helper'

feature 'Top Plus Menu', feature: true, js: true do
  let!(:user) { create :user }
  let!(:group) { create(:group) }
  let!(:public_group) { create(:group, :public) }
  let!(:private_group) { create(:group, :private) }
  let!(:empty_project) { create(:empty_project, group: public_group) }

  before do
    group.add_owner(user)

    login_as(user)

    visit explore_groups_path
  end

  context 'used by full user' do
    before do
      login_as :user
    end

    scenario 'click on New project shows new project page' do
      visit root_dashboard_path

      click_topmenuitem("New project")

      expect(page).to have_content('Project path')
      expect(page).to have_content('Project name')
    end

    scenario 'click on New group shows new group page' do
      visit root_dashboard_path

      click_topmenuitem("New group")

      expect(page).to have_content('Group path')
      expect(page).to have_content('Group name')
    end

    scenario 'click on New snippet shows new snippet page' do
      visit root_dashboard_path
      
      click_topmenuitem("New snippet")

      expect(page).to have_content('New Snippet')
      expect(page).to have_content('Title')
    end

    scenario 'click on New issue shows new issue page' do
      visit namespace_project_path(empty_project.namespace, empty_project)

      click_topmenuitem("New issue")

      expect(page).to have_content('New Issue')
      expect(page).to have_content('Title')
    end

    scenario 'click on New merge request shows new merge request page' do
      visit namespace_project_path(empty_project.namespace, empty_project)

      click_topmenuitem("New merge request")

      expect(page).to have_content('New Merge Request')
      expect(page).to have_content('Source branch')
      expect(page).to have_content('Target branch')
    end

    scenario 'click on New project snippet shows new snippet page' do
      visit namespace_project_path(empty_project.namespace, empty_project)

      page.within '.header-content' do
        find('.header-new-dropdown-toggle').trigger('click')
        expect(page).to have_selector('.header-new.dropdown.open', count: 1)
        find('.header-new-project-snippet a').trigger('click')
      end

      expect(page).to have_content('New Snippet')
      expect(page).to have_content('Title')
    end

    scenario 'Click on New subgroup shows new group page' do
      visit group_path(group)

      click_topmenuitem("New subgroup")

      expect(page).to have_content('Group path')
      expect(page).to have_content('Group name')
    end

    scenario 'Click on New project in group shows new project page' do
      visit group_path(group)

      page.within '.header-content' do
        find('.header-new-dropdown-toggle').trigger('click')
        expect(page).to have_selector('.header-new.dropdown.open', count: 1)
        find('.header-new-group-project a').trigger('click')
      end

      expect(page).to have_content('Project path')
      expect(page).to have_content('Project name')
    end
  end

  def click_topmenuitem(item_name)
    page.within '.header-content' do
      find('.header-new-dropdown-toggle').trigger('click')
      expect(page).to have_selector('.header-new.dropdown.open', count: 1)
      click_link item_name
    end
  end
end
