# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown assignee', :js do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, name: 'administrator', username: 'root') }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:js_dropdown_assignee) { '#js-dropdown-assignee' }
  let(:filter_dropdown) { find("#{js_dropdown_assignee} .filter-dropdown") }

  describe 'behavior' do
    before do
      project.add_maintainer(user)
      sign_in(user)

      visit project_issues_path(project)
    end

    it 'loads all the assignees when opened' do
      input_filtered_search('assignee:=', submit: false, extra_space: false)

      expect_filtered_search_dropdown_results(filter_dropdown, 2)
    end

    it 'shows current user at top of dropdown' do
      input_filtered_search('assignee:=', submit: false, extra_space: false)

      expect(filter_dropdown.first('.filter-dropdown-item')).to have_content(user.name)
    end
  end

  describe 'selecting from dropdown without Ajax call' do
    before do
      project.add_maintainer(user)
      sign_in(user)

      visit project_issues_path(project)

      Gitlab::Testing::RequestBlockerMiddleware.block_requests!
      input_filtered_search('assignee:=', submit: false, extra_space: false)
    end

    after do
      Gitlab::Testing::RequestBlockerMiddleware.allow_requests!
    end

    it 'selects current user' do
      find("#{js_dropdown_assignee} .filter-dropdown-item", text: user.username).click

      expect(page).to have_css(js_dropdown_assignee, visible: false)
      expect_tokens([assignee_token(user.username)])
      expect_filtered_search_input_empty
    end
  end

  context 'assignee suggestions' do
    let!(:group) { create(:group) }
    let!(:group_project) { create(:project, namespace: group) }
    let!(:group_user) { create(:user) }

    let!(:subgroup) { create(:group, parent: group) }
    let!(:subgroup_project) { create(:project, namespace: subgroup) }
    let!(:subgroup_project_issue) { create(:issue, project: subgroup_project) }
    let!(:subgroup_user) { create(:user) }

    let!(:subsubgroup) { create(:group, parent: subgroup) }
    let!(:subsubgroup_project) { create(:project, namespace: subsubgroup) }
    let!(:subsubgroup_user) { create(:user) }

    let!(:invited_to_group_group) { create(:group) }
    let!(:invited_to_group_group_user) { create(:user) }

    let!(:invited_to_project_group) { create(:group) }
    let!(:invited_to_project_group_user) { create(:user) }

    before do
      group.add_developer(group_user)
      subgroup.add_developer(subgroup_user)
      subsubgroup.add_developer(subsubgroup_user)
      invited_to_group_group.add_developer(invited_to_group_group_user)
      invited_to_project_group.add_developer(invited_to_project_group_user)

      create(:group_group_link, shared_group: subgroup, shared_with_group: invited_to_group_group)
      create(:project_group_link, project: subgroup_project, group: invited_to_project_group)

      sign_in(subgroup_user)
    end

    it 'shows inherited, direct, and invited group members but not descendent members', :aggregate_failures do
      visit issues_group_path(subgroup)

      input_filtered_search('assignee:=', submit: false, extra_space: false)

      expect(page).to have_text group_user.name
      expect(page).to have_text subgroup_user.name
      expect(page).to have_text invited_to_group_group_user.name
      expect(page).not_to have_text subsubgroup_user.name
      expect(page).not_to have_text invited_to_project_group_user.name

      visit project_issues_path(subgroup_project)

      input_filtered_search('assignee:=', submit: false, extra_space: false)

      expect(page).to have_text group_user.name
      expect(page).to have_text subgroup_user.name
      expect(page).to have_text invited_to_project_group_user.name
      expect(page).not_to have_text subsubgroup_user.name
      expect(page).not_to have_text invited_to_group_group_user.name
    end
  end
end
