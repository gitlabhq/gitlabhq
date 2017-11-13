require 'spec_helper'

feature 'Top Plus Menu', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, creator: user, namespace: user.namespace) }
  let(:public_project) { create(:project, :public) }

  before do
    group.add_owner(user)
  end

  context 'used by full user' do
    before do
      sign_in(user)
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
      visit project_path(project)

      click_topmenuitem("New issue")

      expect(page).to have_content('New Issue')
      expect(page).to have_content('Title')
    end

    scenario 'click on New merge request shows new merge request page' do
      visit project_path(project)

      click_topmenuitem("New merge request")

      expect(page).to have_content('New Merge Request')
      expect(page).to have_content('Source branch')
      expect(page).to have_content('Target branch')
    end

    scenario 'click on New project snippet shows new snippet page' do
      visit project_path(project)

      page.within '.header-content' do
        find('.header-new-dropdown-toggle').click
        expect(page).to have_selector('.header-new.dropdown.open', count: 1)
        find('.header-new-project-snippet a').click
      end

      expect(page).to have_content('New Snippet')
      expect(page).to have_content('Title')
    end

    scenario 'Click on New subgroup shows new group page', :nested_groups do
      visit group_path(group)

      click_topmenuitem("New subgroup")

      expect(page).to have_content('Group path')
      expect(page).to have_content('Group name')
    end

    scenario 'Click on New project in group shows new project page' do
      visit group_path(group)

      page.within '.header-content' do
        find('.header-new-dropdown-toggle').click
        expect(page).to have_selector('.header-new.dropdown.open', count: 1)
        find('.header-new-group-project a').click
      end

      expect(page).to have_content('Project path')
      expect(page).to have_content('Project name')
    end
  end

  context 'used by guest user' do
    let(:guest_user) { create(:user) }

    before do
      group.add_guest(guest_user)
      project.add_guest(guest_user)

      sign_in(guest_user)
    end

    scenario 'click on New issue shows new issue page' do
      visit project_path(project)

      click_topmenuitem("New issue")

      expect(page).to have_content('New Issue')
      expect(page).to have_content('Title')
    end

    scenario 'has no New merge request menu item' do
      visit project_path(project)

      hasnot_topmenuitem("New merge request")
    end

    scenario 'has no New project snippet menu item' do
      visit project_path(project)

      expect(find('.header-new.dropdown')).not_to have_selector('.header-new-project-snippet')
    end

    scenario 'public project has no New merge request menu item' do
      visit project_path(public_project)

      hasnot_topmenuitem("New merge request")
    end

    scenario 'public project has no New project snippet menu item' do
      visit project_path(public_project)

      expect(find('.header-new.dropdown')).not_to have_selector('.header-new-project-snippet')
    end

    scenario 'has no New subgroup menu item' do
      visit group_path(group)

      hasnot_topmenuitem("New subgroup")
    end

    scenario 'has no New project for group menu item' do
      visit group_path(group)

      expect(find('.header-new.dropdown')).not_to have_selector('.header-new-group-project')
    end
  end

  def click_topmenuitem(item_name)
    page.within '.header-content' do
      find('.header-new-dropdown-toggle').click
      expect(page).to have_selector('.header-new.dropdown.open', count: 1)
      click_link item_name
    end
  end

  def hasnot_topmenuitem(item_name)
    expect(find('.header-new.dropdown')).not_to have_content(item_name)
  end
end
