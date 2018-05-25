require 'rails_helper'

describe 'Issue Boards add issue modal filtering', :js do
  let(:project) { create(:project, :public) }
  let(:board) { create(:board, project: project) }
  let(:planning) { create(:label, project: project, name: 'Planning') }
  let!(:list1) { create(:list, board: board, label: planning, position: 0) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:issue1) { create(:issue, project: project) }

  before do
    project.add_master(user)

    sign_in(user)
  end

  it 'shows empty state when no results found' do
    visit_board

    page.within('.add-issues-modal') do
      find('.form-control').native.send_keys('testing empty state')
      find('.form-control').native.send_keys(:enter)

      wait_for_requests

      expect(page).to have_content('There are no issues to show.')
    end
  end

  it 'restores filters when closing' do
    visit_board

    set_filter('milestone')
    click_filter_link('Upcoming')
    submit_filter

    page.within('.add-issues-modal') do
      wait_for_requests

      expect(page).to have_selector('.board-card', count: 0)

      click_button 'Cancel'
    end

    click_button('Add issues')

    page.within('.add-issues-modal') do
      wait_for_requests

      expect(page).to have_selector('.board-card', count: 1)
    end
  end

  it 'resotres filters after clicking clear button' do
    visit_board

    set_filter('milestone')
    click_filter_link('Upcoming')
    submit_filter

    page.within('.add-issues-modal') do
      wait_for_requests

      expect(page).to have_selector('.board-card', count: 0)

      find('.clear-search').click

      wait_for_requests

      expect(page).to have_selector('.board-card', count: 1)
    end
  end

  context 'author' do
    let!(:issue) { create(:issue, project: project, author: user2) }

    before do
      project.add_developer(user2)

      visit_board
    end

    it 'filters by selected user' do
      set_filter('author')
      click_filter_link(user2.name)
      submit_filter

      page.within('.add-issues-modal') do
        wait_for_requests

        expect(page).to have_selector('.js-visual-token', text: user2.name)
        expect(page).to have_selector('.board-card', count: 1)
      end
    end
  end

  context 'assignee' do
    let!(:issue) { create(:issue, project: project, assignees: [user2]) }

    before do
      project.add_developer(user2)

      visit_board
    end

    it 'filters by unassigned' do
      set_filter('assignee')
      click_filter_link('No Assignee')
      submit_filter

      page.within('.add-issues-modal') do
        wait_for_requests

        expect(page).to have_selector('.js-visual-token', text: 'none')
        expect(page).to have_selector('.board-card', count: 1)
      end
    end

    it 'filters by selected user' do
      set_filter('assignee')
      click_filter_link(user2.name)
      submit_filter

      page.within('.add-issues-modal') do
        wait_for_requests

        expect(page).to have_selector('.js-visual-token', text: user2.name)
        expect(page).to have_selector('.board-card', count: 1)
      end
    end
  end

  context 'milestone' do
    let(:milestone) { create(:milestone, project: project) }
    let!(:issue) { create(:issue, project: project, milestone: milestone) }

    before do
      visit_board
    end

    it 'filters by upcoming milestone' do
      set_filter('milestone')
      click_filter_link('Upcoming')
      submit_filter

      page.within('.add-issues-modal') do
        wait_for_requests

        expect(page).to have_selector('.js-visual-token', text: 'upcoming')
        expect(page).to have_selector('.board-card', count: 0)
      end
    end

    it 'filters by selected milestone' do
      set_filter('milestone')
      click_filter_link(milestone.name)
      submit_filter

      page.within('.add-issues-modal') do
        wait_for_requests

        expect(page).to have_selector('.js-visual-token', text: milestone.name)
        expect(page).to have_selector('.board-card', count: 1)
      end
    end
  end

  context 'label' do
    let(:label) { create(:label, project: project) }
    let!(:issue) { create(:labeled_issue, project: project, labels: [label]) }

    before do
      visit_board
    end

    it 'filters by no label' do
      set_filter('label')
      click_filter_link('No Label')
      submit_filter

      page.within('.add-issues-modal') do
        wait_for_requests

        expect(page).to have_selector('.js-visual-token', text: 'none')
        expect(page).to have_selector('.board-card', count: 1)
      end
    end

    it 'filters by label' do
      set_filter('label')
      click_filter_link(label.title)
      submit_filter

      page.within('.add-issues-modal') do
        wait_for_requests

        expect(page).to have_selector('.js-visual-token', text: label.title)
        expect(page).to have_selector('.board-card', count: 1)
      end
    end
  end

  def visit_board
    visit project_board_path(project, board)
    wait_for_requests

    click_button('Add issues')
  end

  def set_filter(type, text = '')
    find('.add-issues-modal .filtered-search').native.send_keys("#{type}:#{text}")
  end

  def submit_filter
    find('.add-issues-modal .filtered-search').native.send_keys(:enter)
  end

  def click_filter_link(link_text)
    page.within('.add-issues-modal .filtered-search-box') do
      expect(page).to have_button(link_text)

      click_button(link_text)
    end
  end
end
