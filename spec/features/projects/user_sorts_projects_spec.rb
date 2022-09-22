# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sorts projects and order persists' do
  include CookieHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group_member) { create(:group_member, :maintainer, user: user, group: group) }
  let_it_be(:project) { create(:project, :public, group: group) }

  shared_examples_for "sort order persists across all views" do |project_paths_label, group_paths_label|
    it "is set on the dashboard_projects_path" do
      visit(dashboard_projects_path)

      expect(find('#sort-projects-dropdown')).to have_content(project_paths_label)
    end

    it "is set on the explore_projects_path" do
      visit(explore_projects_path)

      expect(find('#sort-projects-dropdown')).to have_content(project_paths_label)
    end

    it "is set on the group_canonical_path" do
      stub_feature_flags(group_overview_tabs_vue: false)
      visit(group_canonical_path(group))

      within '[data-testid=group_sort_by_dropdown]' do
        expect(find('.gl-dropdown-toggle')).to have_content(group_paths_label)
      end
    end

    it "is set on the details_group_path" do
      stub_feature_flags(group_overview_tabs_vue: false)
      visit(details_group_path(group))

      within '[data-testid=group_sort_by_dropdown]' do
        expect(find('.gl-dropdown-toggle')).to have_content(group_paths_label)
      end
    end
  end

  context "from explore projects" do
    before do
      stub_feature_flags(gl_listbox_for_sort_dropdowns: false)
      sign_in(user)
      visit(explore_projects_path)
      find('#sort-projects-dropdown').click
      first(:link, 'Updated date').click
    end

    it_behaves_like "sort order persists across all views", 'Updated date', 'Updated date'
  end

  context 'from dashboard projects' do
    before do
      stub_feature_flags(gl_listbox_for_sort_dropdowns: false)
      sign_in(user)
      visit(dashboard_projects_path)
      find('#sort-projects-dropdown').click
      first(:link, 'Name').click
    end

    it_behaves_like "sort order persists across all views", "Name", "Name"
  end

  context 'from group homepage', :js do
    before do
      stub_feature_flags(gl_listbox_for_sort_dropdowns: false)
      stub_feature_flags(group_overview_tabs_vue: false)
      sign_in(user)
      visit(group_canonical_path(group))
      within '[data-testid=group_sort_by_dropdown]' do
        find('button.gl-dropdown-toggle').click
        first(:button, 'Last created').click
      end
    end

    it_behaves_like "sort order persists across all views", "Created date", "Last created"
  end

  context 'from group details', :js do
    before do
      stub_feature_flags(gl_listbox_for_sort_dropdowns: false)
      stub_feature_flags(group_overview_tabs_vue: false)
      sign_in(user)
      visit(details_group_path(group))
      within '[data-testid=group_sort_by_dropdown]' do
        find('button.gl-dropdown-toggle').click
        first(:button, 'Most stars').click
      end
    end

    it_behaves_like "sort order persists across all views", "Stars", "Most stars"
  end
end
