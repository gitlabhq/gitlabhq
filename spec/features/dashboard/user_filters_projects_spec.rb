# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard > User filters projects', :js, feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'Victorialand', namespace: user.namespace, created_at: 2.seconds.ago, updated_at: 2.seconds.ago) }
  let(:user2) { create(:user) }
  let(:project2) { create(:project, name: 'Treasure', namespace: user2.namespace, created_at: 1.second.ago, updated_at: 1.second.ago) }

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  it 'allows viewing personal projects' do
    project2.add_developer(user)
    visit dashboard_projects_path

    click_link 'Personal'

    expect(page).to have_content(project.name)
    expect(page).not_to have_content(project2.name)
  end

  describe 'starred projects', :js do
    before do
      user.toggle_star(project)

      visit dashboard_projects_path
    end

    it 'allows viewing starred projects' do
      project2.add_developer(user)
      visit dashboard_projects_path

      click_link 'Starred'

      expect(page).to have_content(project.name)
      expect(page).not_to have_content(project2.name)
    end

    it 'shows empty state when starred projects filter returns no results' do
      search('foo')

      expect(page).not_to have_content("You don't have starred projects yet.")
    end
  end

  context 'when feature flag your_work_projects_vue is enabled' do
    it 'searches for projects' do
      project2.add_developer(user)
      visit member_dashboard_projects_path
      wait_for_requests

      expect(page).to have_content(project.name)
      expect(page).to have_content(project2.name)

      search(project.name)

      expect(page).to have_content(project.name)
      expect(page).not_to have_content(project2.name)
    end
  end

  context 'when feature flag your_work_projects_vue is disabled' do
    before do
      stub_feature_flags(your_work_projects_vue: false)
    end

    it 'searches for projects' do
      project2.add_developer(user)
      visit dashboard_projects_path

      expect(page).to have_content(project.name)
      expect(page).to have_content(project2.name)

      search(project.name)

      expect(page).to have_content(project.name)
      expect(page).not_to have_content(project2.name)
    end
  end

  def search(term)
    filter_input = find_by_testid('filtered-search-term-input')
    filter_input.click
    filter_input.set(term)
    click_button 'Search'
    wait_for_requests
  end
end
