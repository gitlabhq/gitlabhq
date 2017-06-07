require 'spec_helper'

describe 'Top Plus Menu', :js, :feature do
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

    scenario 'click on New project shows new project page'
      visit root_dashboard_path

      click_topmenuitem("New project")

      expect(page).to have_content('Project path')
      expect(page).to have_content('Project name')
    end

    scenario 'click on New group shows new group page'
      visit root_dashboard_path

      click_topmenuitem("New group")

      expect(page).to have_content('Group path')
      expect(page).to have_content('Group name')
    end

    scenario 'click on New group shows new group page'
      visit root_dashboard_path
      
      click_topmenuitem("New snippet")

      expect(page).to have_content('New Snippet')
      expect(page).to have_content('Title')
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
