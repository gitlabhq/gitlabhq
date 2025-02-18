# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard Archived Project', feature_category: :groups_and_projects do
  let_it_be(:user) { create :user }
  let_it_be(:project) { create :project }
  let_it_be(:archived_project) { create(:project, :archived) }
  let_it_be(:archived_project_2) { create(:project, :archived) }

  before_all do
    project.add_maintainer(user)
    archived_project.add_maintainer(user)
    archived_project_2.add_maintainer(user)
  end

  context 'when feature flag your_work_projects_vue is enabled', :js do
    before do
      sign_in(user)

      visit member_dashboard_projects_path
      wait_for_requests
    end

    it 'renders non archived projects' do
      expect(page).to have_link(project.name)
      expect(page).not_to have_link(archived_project.name)
    end

    it 'renders only archived projects' do
      click_link 'Inactive'

      expect(page).to have_content(archived_project.name)
      expect(page).not_to have_content(project.name)
    end

    it 'searches archived projects', :js do
      click_link 'Inactive'

      expect(page).to have_link(archived_project.name)
      expect(page).to have_link(archived_project_2.name)

      search(archived_project.name)

      expect(page).not_to have_link(archived_project_2.name)
      expect(page).to have_link(archived_project.name)
    end
  end

  context 'when feature flag your_work_projects_vue is disabled' do
    before do
      stub_feature_flags(your_work_projects_vue: false)
      sign_in(user)

      visit dashboard_projects_path
    end

    it 'renders non archived projects' do
      expect(page).to have_link(project.name)
      expect(page).not_to have_link(archived_project.name)
    end

    it 'renders only archived projects' do
      click_link 'Inactive'

      expect(page).to have_content(archived_project.name)
      expect(page).not_to have_content(project.name)
    end

    it 'searches archived projects', :js do
      click_link 'Inactive'

      expect(page).to have_link(archived_project.name)
      expect(page).to have_link(archived_project_2.name)

      search(archived_project.name)

      expect(page).not_to have_link(archived_project_2.name)
      expect(page).to have_link(archived_project.name)
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
