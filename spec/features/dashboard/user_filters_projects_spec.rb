# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard > User filters projects', feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'Victorialand', namespace: user.namespace, created_at: 2.seconds.ago, updated_at: 2.seconds.ago) }
  let(:user2) { create(:user) }
  let(:project2) { create(:project, name: 'Treasure', namespace: user2.namespace, created_at: 1.second.ago, updated_at: 1.second.ago) }

  before do
    project.add_maintainer(user)

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

    it 'returns message when starred projects filter returns no results' do
      fill_in 'project-filter-form-field', with: 'Beta\n'

      expect(page).to have_content('There are no projects available to be displayed here')
      expect(page).not_to have_content('You don\'t have starred projects yet')
    end
  end

  describe 'without search bar', :js do
    before do
      project2.add_developer(user)
      visit dashboard_projects_path
    end

    it 'autocompletes searches upon typing', :js do
      expect(page).to have_content 'Victorialand'
      expect(page).to have_content 'Treasure'

      fill_in 'project-filter-form-field', with: 'Lord beerus\n'

      expect(page).not_to have_content 'Victorialand'
      expect(page).not_to have_content 'Treasure'
    end
  end
end
