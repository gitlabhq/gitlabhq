# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Multi Select Issue', :js, feature_category: :team_planning do
  include DragTo

  let(:group) { create(:group, :nested) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:board)   { create(:board, project: project) }
  let(:user)    { create(:user) }

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

  def wait_for_board_cards(board_number, expected_cards)
    page.within(find("[data-testid='board-list']:nth-child(#{board_number})")) do
      expect(page.find('.board-header')).to have_content(expected_cards.to_s)
      expect(page).to have_selector('.board-card', count: expected_cards)
    end
  end

  def multi_select(selector, action = 'select')
    element = page.find(selector)
    script = "var el = document.querySelector('#{selector}');"
    script += "var mousedown = new MouseEvent('mousedown', { button: 0, bubbles: true });"
    script += "var mouseup = new MouseEvent('mouseup', { ctrlKey: true, button: 0, bubbles:true });"
    script += "el.dispatchEvent(mousedown); el.dispatchEvent(mouseup);"
    script += "Sortable.utils.#{action}(el);"

    page.execute_script(script, element)
  end

  before do
    project.add_maintainer(user)

    # Multi select drag&drop support is temporarily disabled
    # https://gitlab.com/gitlab-org/gitlab/-/issues/289797
    stub_feature_flags(board_multi_select: project)

    sign_in(user)
  end

  xcontext 'with lists' do
    let(:label1) { create(:label, project: project, name: 'Label 1', description: 'Test') }
    let(:label2) { create(:label, project: project, name: 'Label 2', description: 'Test') }
    let!(:list1) { create(:list, board: board, label: label1, position: 0) }
    let!(:list2) { create(:list, board: board, label: label2, position: 1) }
    let!(:issue1) { create(:labeled_issue, project: project, title: 'Issue 1', description: '', assignees: [user], labels: [label1], relative_position: 1) }
    let!(:issue2) { create(:labeled_issue, project: project, title: 'Issue 2', description: '', author: user, labels: [label1], relative_position: 2) }
    let!(:issue3) { create(:labeled_issue, project: project, title: 'Issue 3', description: '', labels: [label1], relative_position: 3) }
    let!(:issue4) { create(:labeled_issue, project: project, title: 'Issue 4', description: '', labels: [label1], relative_position: 4) }
    let!(:issue5) { create(:labeled_issue, project: project, title: 'Issue 5', description: '', labels: [label1], relative_position: 5) }

    before do
      visit project_board_path(project, board)

      wait_for_requests
    end

    it 'moves multiple issues to another list', :js do
      multi_select('.board-card:nth-child(1)')
      multi_select('.board-card:nth-child(2)')
      drag(list_from_index: 1, list_to_index: 2)

      wait_for_requests

      page.within(all('.board-list')[2]) do
        expect(find('.board-card:nth-child(1)')).to have_content(issue1.title)
        expect(find('.board-card:nth-child(2)')).to have_content(issue2.title)
      end
    end

    it 'maintains order when moved', :js do
      multi_select('.board-card:nth-child(3)')
      multi_select('.board-card:nth-child(2)')
      multi_select('.board-card:nth-child(1)')

      drag(list_from_index: 1, list_to_index: 2)

      wait_for_requests

      page.within(all('.board-list')[2]) do
        expect(find('.board-card:nth-child(1)')).to have_content(issue1.title)
        expect(find('.board-card:nth-child(2)')).to have_content(issue2.title)
        expect(find('.board-card:nth-child(3)')).to have_content(issue3.title)
      end
    end

    it 'move issues in the same list', :js do
      multi_select('.board-card:nth-child(3)')
      multi_select('.board-card:nth-child(4)')

      drag(list_from_index: 1, list_to_index: 1, from_index: 2, to_index: 4)

      wait_for_requests

      page.within(all('.board-list')[1]) do
        expect(find('.board-card:nth-child(1)')).to have_content(issue1.title)
        expect(find('.board-card:nth-child(2)')).to have_content(issue2.title)
        expect(find('.board-card:nth-child(3)')).to have_content(issue5.title)
        expect(find('.board-card:nth-child(4)')).to have_content(issue3.title)
        expect(find('.board-card:nth-child(5)')).to have_content(issue4.title)
      end
    end
  end
end
