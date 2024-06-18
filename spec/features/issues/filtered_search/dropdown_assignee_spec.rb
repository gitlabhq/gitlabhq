# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown assignee', :js, feature_category: :team_planning do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }

  describe 'behavior' do
    before do
      project.add_maintainer(user)
      sign_in(user)

      visit project_issues_path(project)
    end

    it 'loads all the assignees when opened' do
      select_tokens 'Assignee', '='

      # Expect None, Any, administrator, John Doe2
      expect_suggestion_count 4
    end

    it 'shows current user at top of dropdown' do
      select_tokens 'Assignee', '='

      # List items 1 to 3 are None, Any, divider
      expect(page).to have_css('.gl-filtered-search-suggestion:nth-child(4)', text: user.name)
    end
  end

  describe 'selecting from dropdown without Ajax call' do
    before do
      project.add_maintainer(user)
      sign_in(user)

      visit project_issues_path(project)

      Gitlab::Testing::RequestBlockerMiddleware.block_requests!
      select_tokens 'Assignee', '='
    end

    after do
      Gitlab::Testing::RequestBlockerMiddleware.allow_requests!
    end

    it 'selects current user' do
      click_on user.username

      expect_assignee_token(user.username)
      expect_empty_search_term
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

    it 'shows inherited, direct, and invited group members including descendent members', :aggregate_failures do
      visit issues_group_path(subgroup)

      select_tokens 'Assignee', '='

      expect(page).to have_text group_user.name
      expect(page).to have_text subgroup_user.name
      expect(page).to have_text invited_to_group_group_user.name
      expect(page).to have_text subsubgroup_user.name
      expect(page).to have_text invited_to_project_group_user.name

      visit project_issues_path(subgroup_project)

      select_tokens 'Assignee', '='

      expect(page).to have_text group_user.name
      expect(page).to have_text subgroup_user.name
      expect(page).to have_text invited_to_project_group_user.name
      expect(page).to have_text invited_to_group_group_user.name
      expect(page).not_to have_text subsubgroup_user.name
    end
  end
end
