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

      expect(find('.dropdown-menu a.is-active', text: project_paths_label)).to have_content(project_paths_label)
    end

    it "is set on the explore_projects_path" do
      visit(explore_projects_path)

      expect(find('.dropdown-menu a.is-active', text: project_paths_label)).to have_content(project_paths_label)
    end

    it "is set on the group_canonical_path" do
      visit(group_canonical_path(group))

      expect(find('.dropdown-menu a.is-active', text: group_paths_label)).to have_content(group_paths_label)
    end

    it "is set on the details_group_path" do
      visit(details_group_path(group))

      expect(find('.dropdown-menu a.is-active', text: group_paths_label)).to have_content(group_paths_label)
    end
  end

  context "from explore projects" do
    before do
      sign_in(user)
      visit(explore_projects_path)
      find('#sort-projects-dropdown').click
      first(:link, 'Last updated').click
    end

    it_behaves_like "sort order persists across all views", "Last updated", "Last updated"
  end

  context 'from dashboard projects' do
    before do
      sign_in(user)
      visit(dashboard_projects_path)
      find('#sort-projects-dropdown').click
      first(:link, 'Name').click
    end

    it_behaves_like "sort order persists across all views", "Name", "Name"
  end

  context 'from group homepage' do
    before do
      sign_in(user)
      visit(group_canonical_path(group))
      find('button.dropdown-menu-toggle').click
      first(:link, 'Last created').click
    end

    it_behaves_like "sort order persists across all views", "Created date", "Last created"
  end

  context 'from group details' do
    before do
      sign_in(user)
      visit(details_group_path(group))
      find('button.dropdown-menu-toggle').click
      first(:link, 'Most stars').click
    end

    it_behaves_like "sort order persists across all views", "Stars", "Most stars"
  end
end
