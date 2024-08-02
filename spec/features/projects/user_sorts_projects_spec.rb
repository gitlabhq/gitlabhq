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

  shared_examples_for "sort order persists across all views" do |sort_label|
    it "is set on the dashboard_projects_path" do
      visit(dashboard_projects_path)

      within '[data-testid=groups-projects-sort]' do
        expect(find_dropdown_toggle).to have_content(sort_label)
      end
    end

    it "is set on the explore_projects_path" do
      visit(explore_projects_path)

      within '[data-testid=groups-projects-sort]' do
        expect(find_dropdown_toggle).to have_content(sort_label)
      end
    end

    it "is set on the group_canonical_path" do
      visit(group_canonical_path(group))

      within '[data-testid=groups-projects-sort]' do
        expect(find_dropdown_toggle).to have_content(sort_label)
      end
    end

    it "is set on the details_group_path" do
      visit(details_group_path(group))

      within '[data-testid=groups-projects-sort]' do
        expect(find_dropdown_toggle).to have_content(sort_label)
      end
    end
  end

  context "from explore projects", :js do
    before do
      sign_in(user)
      visit(explore_projects_path)
      within '[data-testid=groups-projects-sort]' do
        find_dropdown_toggle.click
        find('li', text: 'Name').click
        wait_for_requests
      end
    end

    it_behaves_like "sort order persists across all views", 'Name'
  end

  context 'from dashboard projects', :js do
    before do
      sign_in(user)
      visit(dashboard_projects_path)
      within '[data-testid=groups-projects-sort]' do
        find_dropdown_toggle.click
        find('li', text: 'Created').click
        wait_for_requests
      end
    end

    it_behaves_like "sort order persists across all views", "Created"
  end

  context 'from group homepage', :js do
    before do
      sign_in(user)
      visit(group_canonical_path(group))
      within '[data-testid=groups-projects-sort]' do
        find_dropdown_toggle.click
        find('li', text: 'Created').click
        wait_for_requests
      end
    end

    it_behaves_like "sort order persists across all views", "Created"
  end

  context 'from group details', :js do
    before do
      sign_in(user)
      visit(details_group_path(group))
      within '[data-testid=groups-projects-sort]' do
        find_dropdown_toggle.click
        find('li', text: 'Updated').click
        wait_for_requests
      end
    end

    it_behaves_like "sort order persists across all views", "Updated"
  end
end
