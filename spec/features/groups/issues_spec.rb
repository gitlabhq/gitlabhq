# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group issues page', feature_category: :team_planning do
  include Features::SortingHelpers
  include FilteredSearchHelpers
  include DragTo

  let(:group) { create(:group) }
  let(:project) { create(:project, :public, group: group) }
  let(:project_with_issues_disabled) { create(:project, :issues_disabled, group: group) }
  let(:path) { issues_group_path(group) }

  context 'with shared examples', :js do
    let(:issuable) { create(:issue, project: project, title: "this is my created issuable") }

    include_examples 'project features apply to issuables', Issue

    context 'rss feed' do
      let(:access_level) { ProjectFeature::ENABLED }

      before do
        click_button 'Actions'
      end

      context 'when signed in' do
        let(:user) do
          user_in_group.ensure_feed_token
          user_in_group.save!
          user_in_group
        end

        it_behaves_like "it has an RSS link with current_user's feed token"
        it_behaves_like "an autodiscoverable RSS feed with current_user's feed token"
      end

      context 'when signed out' do
        let(:user) { nil }

        it_behaves_like "it has an RSS link without a feed token"
        it_behaves_like "an autodiscoverable RSS feed without a feed token"
      end
    end

    context 'assignee' do
      let(:access_level) { ProjectFeature::ENABLED }
      let(:user) { user_in_group }
      let(:user2) { user_outside_group }

      it 'filters by only group users' do
        select_tokens 'Assignee', '='

        expect_suggestion(user.name)
        expect_no_suggestion(user2.name)
      end
    end
  end

  context 'issues list', :js do
    let(:subgroup) { create(:group, parent: group) }
    let(:subgroup_project) { create(:project, :public, group: subgroup) }
    let(:user_in_group) { create(:group_member, :maintainer, user: create(:user), group: group).user }
    let!(:issue) { create(:issue, project: project, title: 'root group issue') }
    let!(:subgroup_issue) { create(:issue, project: subgroup_project, title: 'subgroup issue') }

    it 'returns all group and subgroup issues' do
      visit issues_group_path(group)

      expect(page).to have_selector('li.issue', count: 2)
      expect(page).to have_content('root group issue')
      expect(page).to have_content('subgroup issue')
    end

    context 'when project is archived' do
      before do
        ::Projects::UpdateService.new(project, user_in_group, archived: true).execute
      end

      it 'does not render issue' do
        visit path

        expect(page).not_to have_content issue.title[0..80]
      end
    end
  end

  context 'group with no issues', :js do
    let!(:group_with_no_issues) { create(:group) }
    let!(:subgroup_with_issues) { create(:group, parent: group_with_no_issues) }
    let!(:subgroup_project) { create(:project, :public, group: subgroup_with_issues) }
    let!(:subgroup_issue) { create(:issue, project: subgroup_project) }

    before do
      visit issues_group_path(group_with_no_issues)
    end

    it 'shows issues from subgroups on issues list' do
      expect(page).to have_text subgroup_issue.title
    end
  end

  context 'projects with issues disabled' do
    describe 'issue dropdown' do
      let(:user_in_group) { create(:group_member, :maintainer, user: create(:user), group: group).user }

      before do
        [project, project_with_issues_disabled].each { |project| project.add_maintainer(user_in_group) }
        sign_in(user_in_group)
        visit issues_group_path(group)
      end

      it 'shows projects only with issues feature enabled', :js do
        click_button 'Toggle project select'

        expect(page).to have_button project.full_name
        expect(page).not_to have_button project_with_issues_disabled.full_name
      end
    end
  end

  context 'manual ordering', :js do
    let(:user_in_group) { create(:group_member, :maintainer, user: create(:user), group: group).user }

    let!(:issue1) { create(:issue, project: project, title: 'Issue #1', relative_position: 1) }
    let!(:issue2) { create(:issue, project: project, title: 'Issue #2', relative_position: 2) }
    let!(:issue3) { create(:issue, project: project, title: 'Issue #3', relative_position: 3) }

    before do
      sign_in(user_in_group)
    end

    it 'displays all issues' do
      visit issues_group_path(group, sort: 'relative_position')

      expect(page).to have_selector('li.issue', count: 3)
    end

    it 'has manual-ordering css applied' do
      visit issues_group_path(group, sort: 'relative_position')

      expect(page).to have_selector('.manual-ordering')
    end

    it 'each issue item has a gl-cursor-grab css applied' do
      visit issues_group_path(group, sort: 'relative_position')

      expect(page).to have_selector('.issue.gl-cursor-grab', count: 3)
    end

    it 'issues should be draggable and persist order' do
      visit issues_group_path(group)
      select_manual_sort

      wait_for_requests

      drag_to(selector: '.manual-ordering', from_index: 0, to_index: 2)

      expect_issue_order

      visit issues_group_path(group)

      expect_issue_order
    end

    it 'issues should not be draggable when user is not logged in' do
      sign_out(user_in_group)
      wait_for_requests
      visit issues_group_path(group)
      select_manual_sort

      wait_for_requests

      drag_to(selector: '.manual-ordering', from_index: 0, to_index: 2)

      expect(page).to have_text 'An error occurred while reordering issues.'
    end

    def select_manual_sort
      pajamas_sort_by 'Manual', from: 'Created date'
      wait_for_requests
    end

    def expect_issue_order
      expect(page).to have_css('.issue:nth-child(1) .title', text: 'Issue #2')
      expect(page).to have_css('.issue:nth-child(2) .title', text: 'Issue #3')
      expect(page).to have_css('.issue:nth-child(3) .title', text: 'Issue #1')
    end
  end

  context 'issues pagination', :js do
    let(:user_in_group) { create(:group_member, :maintainer, user: create(:user), group: group).user }

    let!(:issues) do
      (1..25).to_a.map { |index| create(:issue, project: project, title: "Issue #{index}") }
    end

    before do
      sign_in(user_in_group)
      visit issues_group_path(group)
    end

    it 'shows the pagination' do
      expect(page).to have_button 'Prev', disabled: true
      expect(page).to have_button 'Next'
    end
  end
end
