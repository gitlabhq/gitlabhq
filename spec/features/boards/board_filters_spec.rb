# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue board filters', :js do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:board) { create(:board, project: project) }
  let_it_be(:milestone_1) { create(:milestone, project: project) }
  let_it_be(:milestone_2) { create(:milestone, project: project) }
  let_it_be(:release) { create(:release, tag: 'v1.0', project: project, milestones: [milestone_1]) }
  let_it_be(:release_2) { create(:release, tag: 'v2.0', project: project, milestones: [milestone_2]) }
  let_it_be(:issue) { create(:issue, project: project, milestone: milestone_1) }
  let_it_be(:issue_2) { create(:issue, project: project, milestone: milestone_2) }

  let(:filtered_search) { find('[data-testid="issue-board-filtered-search"]') }
  let(:filter_input) { find('.gl-filtered-search-term-input')}
  let(:filter_dropdown) { find('.gl-filtered-search-suggestion-list') }
  let(:filter_first_suggestion) { find('.gl-filtered-search-suggestion-list').first('.gl-filtered-search-suggestion') }
  let(:filter_submit) { find('.gl-search-box-by-click-search-button') }

  before do
    stub_feature_flags(issue_boards_filtered_search: true)

    project.add_maintainer(user)
    sign_in(user)

    visit_project_board
  end

  describe 'filters by releases' do
    before do
      filter_input.click
      filter_input.set('release:')
      filter_first_suggestion.click # Select `=` operator
    end

    it 'loads all the releases when opened and submit one as filter', :aggregate_failures do
      expect(find('.board:nth-child(1)')).to have_selector('.board-card', count: 2)

      expect_filtered_search_dropdown_results(filter_dropdown, 2)

      click_on release.tag
      filter_submit.click

      expect(find('.board:nth-child(1)')).to have_selector('.board-card', count: 1)
    end
  end

  def expect_filtered_search_dropdown_results(filter_dropdown, count)
    expect(filter_dropdown).to have_selector('.gl-new-dropdown-item', count: count)
  end

  def visit_project_board
    visit project_board_path(project, board)
    wait_for_requests
  end
end
