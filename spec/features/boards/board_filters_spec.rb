# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue board filters', :js, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project_label) { create(:label, project: project, title: 'Label') }
  let_it_be(:milestone_1) { create(:milestone, project: project, due_date: 3.days.from_now) }
  let_it_be(:milestone_2) { create(:milestone, project: project, due_date: Date.tomorrow) }
  let_it_be(:release) { create(:release, tag: 'v1.0', project: project, milestones: [milestone_1]) }
  let_it_be(:release_2) { create(:release, tag: 'v2.0', project: project, milestones: [milestone_2]) }
  let_it_be(:issue_1) { create(:issue, project: project, milestone: milestone_1, author: user) }
  let_it_be(:issue_2) { create(:labeled_issue, project: project, milestone: milestone_2, assignees: [user], labels: [project_label], confidential: true) }
  let_it_be(:award_emoji1) { create(:award_emoji, name: AwardEmoji::THUMBS_UP, user: user, awardable: issue_1) }

  let(:filtered_search) { find_by_testid('issue-board-filtered-search') }
  let(:filter_input) { find('.gl-filtered-search-term-input') }
  let(:filter_dropdown) { find('.gl-filtered-search-suggestion-list') }
  let(:filter_first_suggestion) { find('.gl-filtered-search-suggestion-list').first('.gl-filtered-search-suggestion') }
  let(:filter_submit) { find('.gl-search-box-by-click-search-button') }

  context 'for a project board' do
    let_it_be(:board) { create(:board, project: project) }

    before do
      project.add_maintainer(user)
      sign_in(user)

      visit project_board_path(project, board)
      wait_for_requests
    end

    shared_examples 'loads all the users when opened' do
      it 'and submit one as filter', :aggregate_failures do
        expect(find('[data-testid="board-list"]:nth-child(1)')).to have_selector('.board-card', count: 2)

        wait_for_requests

        expect_filtered_search_dropdown_results(filter_dropdown, 3)

        click_on user.username
        filter_submit.click

        expect(find('[data-testid="board-list"]:nth-child(1)')).to have_selector('.board-card', count: 1)
        expect(find('.board-card')).to have_content(issue.title)
      end
    end

    describe 'filters by assignee', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/351426' do
      before do
        set_filter('assignee')
      end

      it_behaves_like 'loads all the users when opened' do
        let(:issue) { issue_2 }
      end
    end

    describe 'filters by author' do
      before do
        set_filter('author')
      end

      it_behaves_like 'loads all the users when opened' do
        let(:issue) { issue_1 }
      end
    end

    describe 'filters by label' do
      before do
        set_filter('label')
      end

      it 'loads all the labels when opened and submit one as filter', :aggregate_failures do
        expect(find('[data-testid="board-list"]:nth-child(1)')).to have_selector('.board-card', count: 2)

        expect_filtered_search_dropdown_results(filter_dropdown, 3)

        filter_dropdown.click_on project_label.title
        filter_submit.click

        expect(find('[data-testid="board-list"]:nth-child(1)')).to have_selector('.board-card', count: 1)
        expect(find('.board-card')).to have_content(issue_2.title)
      end
    end

    describe 'filters by releases' do
      before do
        set_filter('release')
      end

      it 'loads all the releases when opened and submit one as filter', :aggregate_failures do
        expect(find('[data-testid="board-list"]:nth-child(1)')).to have_selector('.board-card', count: 2)

        expect_filtered_search_dropdown_results(filter_dropdown, 2)

        click_on release.tag
        filter_submit.click

        expect(find('[data-testid="board-list"]:nth-child(1)')).to have_selector('.board-card', count: 1)
        expect(find('.board-card')).to have_content(issue_1.title)
      end
    end

    describe 'filters by confidentiality' do
      before do
        filter_input.click
        filter_input.set("confidential:")
      end

      it 'loads all the confidentiality options when opened and submit one as filter', :aggregate_failures do
        expect(find('[data-testid="board-list"]:nth-child(1)')).to have_selector('.board-card', count: 2)

        expect_filtered_search_dropdown_results(filter_dropdown, 2)

        filter_dropdown.click_on 'Yes'
        filter_submit.click

        expect(find('[data-testid="board-list"]:nth-child(1)')).to have_selector('.board-card', count: 1)
        expect(find('.board-card')).to have_content(issue_2.title)
      end
    end

    describe 'filters by milestone' do
      before do
        set_filter('milestone')
      end

      it 'loads all the milestones when opened and submit one as filter', :aggregate_failures do
        expect(find('[data-testid="board-list"]:nth-child(1)')).to have_selector('.board-card', count: 2)

        expect_filtered_search_dropdown_results(filter_dropdown, 6)
        expect(filter_dropdown).to have_content('None')
        expect(filter_dropdown).to have_content('Any')
        expect(filter_dropdown).to have_content('Started')
        expect(filter_dropdown).to have_content('Upcoming')

        dropdown_nodes = page.find_all('.gl-filtered-search-suggestion-list > .gl-filtered-search-suggestion')

        expect(dropdown_nodes[4]).to have_content(milestone_2.title)
        expect(dropdown_nodes.last).to have_content(milestone_1.title)

        click_on milestone_1.title
        filter_submit.click

        expect(find('[data-testid="board-list"]:nth-child(1)')).to have_selector('.board-card', count: 1)
      end
    end

    describe 'filters by reaction emoji' do
      before do
        set_filter('my-reaction')
      end

      it 'loads all the emojis when opened and submit one as filter', :aggregate_failures do
        expect(find('[data-testid="board-list"]:nth-child(1)')).to have_selector('.board-card', count: 2)

        expect_filtered_search_dropdown_results(filter_dropdown, 3)

        click_on AwardEmoji::THUMBS_UP
        filter_submit.click

        expect(find('[data-testid="board-list"]:nth-child(1)')).to have_selector('.board-card', count: 1)
        expect(find('.board-card')).to have_content(issue_1.title)
      end
    end

    describe 'filters by type' do
      let_it_be(:incident) { create(:incident, project: project) }

      before do
        set_filter('type')
      end

      it 'loads all the types when opened and submit one as filter', :aggregate_failures do
        expect(find('[data-testid="board-list"]:nth-child(1)')).to have_selector('.board-card', count: 3)

        expect_filtered_search_dropdown_results(filter_dropdown, 3)

        click_on 'Incident'
        filter_submit.click

        expect(find('[data-testid="board-list"]:nth-child(1)')).to have_selector('.board-card', count: 1)
        expect(find('.board-card')).to have_content(incident.title)
      end
    end
  end

  context 'for a group board' do
    let_it_be(:board) { create(:board, group: group) }

    let_it_be(:child_project_member) { create(:user, maintainer_of: project) }

    before do
      group.add_maintainer(user)
      sign_in(user)
    end

    context 'when filtering by assignee' do
      it 'includes descendant project members in autocomplete' do
        visit group_board_path(group, board)
        wait_for_requests

        set_filter('assignee')

        expect(page).to have_css('.gl-filtered-search-suggestion', text: child_project_member.name)
      end
    end
  end

  def set_filter(filter)
    filter_input.click
    filter_input.set("#{filter}:")
    filter_first_suggestion.click # Select `=` operator
  end

  def expect_filtered_search_dropdown_results(filter_dropdown, count)
    expect(filter_dropdown).to have_selector('.gl-dropdown-item', count: count)
  end
end
