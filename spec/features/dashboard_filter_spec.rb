require 'spec_helper'

describe "Dashboard projects filters", feature: true, js: true do

  context 'filtering personal projects' do
    before do
      user = create(:user)
      project = create(:project, name: "Victorialand", namespace: user.namespace)
      project.team << [user, :master]

      login_as(user)
      visit dashboard_projects_path

      open_filter_dropdown
      click_link "Owned by me"
    end

    it 'filters by projects "Owned by me"' do
      sleep 1
      open_filter_dropdown
      page.within('ul.dropdown-menu.dropdown-menu-align-right') do
        expect(page).to have_css('.is-active', text: 'Owned by me')
      end
    end
  end

  def open_filter_dropdown
    find('button.dropdown-toggle.btn').click
  end
end
