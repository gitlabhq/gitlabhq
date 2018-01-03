require 'spec_helper'

describe 'Dashboard > User filters projects' do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'Victorialand', namespace: user.namespace) }
  let(:user2) { create(:user) }
  let(:project2) { create(:project, name: 'Treasure', namespace: user2.namespace) }

  before do
    project.add_master(user)

    sign_in(user)
  end

  describe 'filtering personal projects' do
    before do
      project2.add_developer(user)

      visit dashboard_projects_path
    end

    it 'filters by projects "Owned by me"' do
      click_link 'Owned by me'

      expect(page).to have_css('.is-active', text: 'Owned by me')
      expect(page).to have_content('Victorialand')
      expect(page).not_to have_content('Treasure')
    end
  end

  describe 'filtering starred projects', :js do
    before do
      user.toggle_star(project)

      visit dashboard_projects_path
    end

    it 'returns message when starred projects fitler returns no results' do
      fill_in 'project-filter-form-field', with: 'Beta\n'

      expect(page).to have_content('No projects found')
      expect(page).not_to have_content('You don\'t have starred projects yet')
    end
  end
end
