# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sorts projects and order persists', feature_category: :groups_and_projects do
  include CookieHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group_member) { create(:group_member, :maintainer, user: user, group: group) }
  let_it_be(:project) { create(:project, :public, group: group) }

  def find_dropdown_toggle
    find('button[data-testid=base-dropdown-toggle]')
  end

  context "when sort is set from explore projects page", :js do
    before do
      sign_in(user)
      visit(explore_projects_path)
      within '[data-testid=groups-projects-sort]' do
        find_dropdown_toggle.click
        find('li', text: 'Name').click
        wait_for_requests
      end
    end

    it "persists when revisiting explore projects" do
      visit(explore_projects_path)
      within '[data-testid=groups-projects-sort]' do
        expect(find_dropdown_toggle).to have_content('Name')
      end
    end
  end

  context 'when sort is set from dashboard projects page', :js do
    before do
      sign_in(user)
      visit(dashboard_projects_path)
      within '[data-testid=groups-projects-sort]' do
        find_dropdown_toggle.click
        find('li', text: 'Created').click
        wait_for_requests
      end
    end

    it "persists when revisiting dashboard projects" do
      visit(dashboard_projects_path)
      within '[data-testid=groups-projects-sort]' do
        expect(find_dropdown_toggle).to have_content('Created')
      end
    end
  end

  context 'when sort is set from dashboard groups page', :js do
    before do
      sign_in(user)
      visit(dashboard_groups_path)
      within '[data-testid=groups-projects-sort]' do
        find_dropdown_toggle.click
        find('li', text: 'Name').click
        wait_for_requests
      end
    end

    it "persists when revisiting dashboard groups" do
      visit(dashboard_groups_path)
      within '[data-testid=groups-projects-sort]' do
        expect(find_dropdown_toggle).to have_content('Name')
      end
    end
  end
end
