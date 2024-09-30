# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Boards', :js, feature_category: :portfolio_management do
  include DragTo

  let(:project) { create(:project, :public) }
  let(:board) { create(:board, project: project) }
  let(:user) { create(:user) }
  let(:label) { create(:label, project: project) }
  let!(:list1) { create(:list, board: board, label: label, position: 0) }
  let!(:issue1) { create(:labeled_issue, project: project, title: 'testing 1', labels: [label], relative_position: 3) }
  let!(:issue2) { create(:labeled_issue, project: project, title: 'testing 2', labels: [label], relative_position: 2) }
  let!(:issue3) { create(:labeled_issue, project: project, title: 'testing 3', labels: [label], relative_position: 1) }

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  context 'un-ordered issues' do
    let!(:issue4) { create(:labeled_issue, project: project, labels: [label], relative_position: nil) }

    before do
      visit project_board_path(project, board)
      wait_for_requests

      expect(page).to have_selector('.board', count: 3)
    end

    it 'has un-ordered issue as last issue' do
      page.within(find('[data-testid="board-list"]:nth-child(2)')) do
        expect(all('.board-card').last).to have_content(issue4.title)
      end
    end

    it 'moves un-ordered issue to top of list' do
      drag(from_index: 3, to_index: 0, duration: 1180)

      wait_for_requests

      page.within(find('[data-testid="board-list"]:nth-child(2)')) do
        expect(first('.board-card')).to have_content(issue4.title)
      end
    end
  end

  context 'closed issues' do
    let!(:issue7) { create(:closed_issue, project: project, title: 'Closed issue 1', closed_at: 1.day.ago) }
    let!(:issue8) { create(:closed_issue, project: project, title: 'Closed issue 2', closed_at: 1.week.ago) }
    let!(:issue9) { create(:closed_issue, project: project, title: 'Closed issue 3', closed_at: 2.weeks.ago) }

    before do
      visit project_board_path(project, board)
      wait_for_requests

      expect(page).to have_selector('.board', count: 3)
    end

    it 'orders issues by closed_at' do
      wait_for_requests

      page.within(find('[data-testid="board-list"]:nth-child(3)')) do
        first, second, third = all('.board-card').to_a

        expect(first).to have_content(issue7.title)
        expect(second).to have_content(issue8.title)
        expect(third).to have_content(issue9.title)
      end
    end
  end

  context 'ordering in list' do
    before do
      visit project_board_path(project, board)
      wait_for_requests

      expect(page).to have_selector('.board', count: 3)
    end

    it 'moves from middle to top' do
      drag(from_index: 1, to_index: 0)

      wait_for_requests

      expect(first('.board-card')).to have_content(issue2.title)
    end

    it 'moves from middle to bottom' do
      drag(from_index: 1, to_index: 2)

      wait_for_requests

      expect(all('.board-card').last).to have_content(issue2.title)
    end

    it 'moves from top to bottom' do
      drag(from_index: 0, to_index: 2)

      wait_for_requests

      expect(all('.board-card').last).to have_content(issue3.title)
    end

    it 'moves from bottom to top' do
      drag(from_index: 2, to_index: 0, duration: 1020)

      wait_for_requests

      expect(first('.board-card')).to have_content(issue1.title)
    end

    it 'moves from top to middle' do
      drag(from_index: 0, to_index: 1)

      wait_for_requests

      expect(first('.board-card')).to have_content(issue2.title)
    end

    it 'moves from bottom to middle' do
      drag(from_index: 2, to_index: 1)

      wait_for_requests

      expect(all('.board-card').last).to have_content(issue2.title)
    end
  end

  context 'ordering in list using move to position' do
    let(:move_to_position) { find_by_testid('board-move-to-position') }

    before do
      visit project_board_path(project, board)
      wait_for_requests
    end

    it 'moves to end of list', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/410100' do
      expect(all('.board-card').first).to have_content(issue3.title)

      page.within(find('[data-testid="board-list"]:nth-child(2)')) do
        first('.board-card').hover
        move_to_position.click

        click_button 'Move to end of list'
      end

      expect(all('.board-card').last).to have_content(issue3.title)
    end

    it 'moves to start of list', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/410100' do
      expect(all('.board-card').last).to have_content(issue1.title)

      page.within(find('[data-testid="board-list"]:nth-child(2)')) do
        all('.board-card').last.hover
        move_to_position.click

        click_button 'Move to start of list'
      end

      expect(all('.board-card').first).to have_content(issue1.title)
    end
  end

  context 'ordering when changing list' do
    let(:label2) { create(:label, project: project) }
    let!(:list2) { create(:list, board: board, label: label2, position: 1) }
    let!(:issue4) { create(:labeled_issue, project: project, title: 'testing 1', labels: [label2], relative_position: 3.0) }
    let!(:issue5) { create(:labeled_issue, project: project, title: 'testing 2', labels: [label2], relative_position: 2.0) }
    let!(:issue6) { create(:labeled_issue, project: project, title: 'testing 3', labels: [label2], relative_position: 1.0) }

    before do
      visit project_board_path(project, board)
      wait_for_requests

      expect(page).to have_selector('.board', count: 4)
    end

    it 'moves to top of another list' do
      drag(list_from_index: 1, list_to_index: 2)

      wait_for_requests

      expect(find('[data-testid="board-list"]:nth-child(2)')).to have_selector('.board-card', count: 2)
      expect(all('.board')[2]).to have_selector('.board-card', count: 4)

      page.within(all('.board')[2]) do
        expect(first('.board-card')).to have_content(issue3.title)
      end
    end

    it 'moves to bottom of another list' do
      drag(list_from_index: 1, list_to_index: 2, to_index: 3, duration: 1020)

      wait_for_requests

      expect(find('[data-testid="board-list"]:nth-child(2)')).to have_selector('.board-card', count: 2)
      expect(all('.board')[2]).to have_selector('.board-card', count: 4)

      page.within(all('.board')[2]) do
        expect(all('.board-card').last).to have_content(issue3.title)
      end
    end

    it 'moves to index of another list' do
      drag(list_from_index: 1, list_to_index: 2, to_index: 1)

      wait_for_requests

      expect(find('[data-testid="board-list"]:nth-child(2)')).to have_selector('.board-card', count: 2)
      expect(all('.board')[2]).to have_selector('.board-card', count: 4)

      page.within(all('.board')[2]) do
        expect(all('.board-card')[1]).to have_content(issue3.title)
      end
    end
  end

  def drag(selector: '.board-list', list_from_index: 1, from_index: 0, to_index: 0, list_to_index: 1, duration: 1000)
    drag_to(
      selector: selector,
      scrollable: '#board-app',
      list_from_index: list_from_index,
      from_index: from_index,
      to_index: to_index,
      list_to_index: list_to_index,
      duration: duration
    )
  end
end
