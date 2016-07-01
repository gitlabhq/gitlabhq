require 'spec_helper'

describe "Dashboard > User filters projects", feature: true do
  describe 'filtering personal projects' do
    before do
      user = create(:user)
      project = create(:project, name: "Victorialand", namespace: user.namespace)
      project.team << [user, :master]

      user2 = create(:user)
      project2 = create(:project, name: "Treasure", namespace: user2.namespace)
      project2.team << [user, :developer]

      login_as(user)
      visit dashboard_projects_path
    end

    it 'filters by projects "Owned by me"' do
      click_link "Owned by me"

      expect(page).to have_css('.is-active', text: 'Owned by me')
      expect(page).to have_content('Victorialand')
      expect(page).not_to have_content('Treasure')
    end
  end
end
