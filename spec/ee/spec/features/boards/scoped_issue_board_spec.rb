require 'rails_helper'

describe 'Scoped issue boards', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let!(:milestone) { create(:milestone, project: project) }
  let!(:issue) { create(:closed_issue, project: project) }
  let!(:issue_with_milestone) { create(:closed_issue, project: project, milestone: milestone) }
  let!(:label) { create(:label, project: project) }
  let!(:issue_with_label) { create(:labeled_issue, :closed, project: project, labels: [label]) }
  let!(:issue_with_assignee) { create(:closed_issue, project: project, assignees: [user]) }
  let!(:issue_with_weight) { create(:labeled_issue, :closed, project: project, weight: 5) }

  before do
    allow_any_instance_of(ApplicationHelper).to receive(:collapsed_sidebar?).and_return(true)

    project.team << [user, :master]

    sign_in(user)
  end

  context 'with the feature enabled' do
    before do
      stub_licensed_features(scoped_issue_board: true)
    end

    context 'new board' do
      before do
        visit project_boards_path(project)
      end

      it 'creates board with milestone' do
        create_board_with_milestone

        expect(find('.tokens-container')).to have_content(milestone.title)
        wait_for_requests
        find('.card', match: :first)

        expect(all('.board').last).to have_selector('.card', count: 1)
      end

      it 'creates board with labels' do
        create_board_with_labels

        expect(find('.tokens-container')).to have_content(label.title)
        wait_for_requests
        find('.card', match: :first)

        expect(all('.board').last).to have_selector('.card', count: 1)
      end

      it 'creates board with assignee' do
        create_board_with_assignee

        expect(find('.tokens-container')).to have_content(user.name)
        wait_for_requests
        find('.card', match: :first)

        expect(all('.board').last).to have_selector('.card', count: 1)
      end

      it 'creates board with weight' do
        create_board_with_weight

        expect(find('.tokens-container')).to have_content(issue_with_weight.weight)
        wait_for_requests
        find('.card', match: :first)

        expect(all('.board').last).to have_selector('.card', count: 1)
      end
    end

    xcontext 'update board' do
      let!(:milestone_two) { create(:milestone, project: project) }
      let!(:board) { create(:board, project: project, milestone: milestone) }

      before do
        visit project_boards_path(project)
      end

      it 'defaults milestone filter' do
        page.within '#js-multiple-boards-switcher' do
          find('.dropdown-menu-toggle').click

          wait_for_requests

          click_link board.name
        end

        expect(find('.tokens-container')).to have_content(milestone.title)

        find('.card', match: :first)

        expect(all('.board').last).to have_selector('.card', count: 1)
      end

      it 'sets board to any milestone' do
        update_board_milestone('Any Milestone')

        expect(page).not_to have_css('.js-visual-token')
        expect(find('.tokens-container')).not_to have_content(milestone.title)

        find('.card', match: :first)

        expect(page).to have_selector('.board', count: 3)
        expect(all('.board').last).to have_selector('.card', count: 2)
      end

      it 'sets board to upcoming milestone' do
        update_board_milestone('Upcoming')

        expect(find('.tokens-container')).not_to have_content(milestone.title)

        find('.board', match: :first)

        expect(all('.board')[1]).to have_selector('.card', count: 0)
      end

      it 'does not allow milestone in filter to be editted' do
        find('.filtered-search').native.send_keys(:backspace)

        page.within('.tokens-container') do
          expect(page).to have_selector('.value')
        end
      end

      it 'does not render milestone in hint dropdown' do
        find('.filtered-search').click

        page.within('#js-dropdown-hint') do
          expect(page).not_to have_button('Milestone')
        end
      end
    end

    xcontext 'removing issue from board' do
      let(:label) { create(:label, project: project) }
      let!(:issue) { create(:labeled_issue, project: project, labels: [label], milestone: milestone) }
      let!(:board) { create(:board, project: project, milestone: milestone) }
      let!(:list) { create(:list, board: board, label: label, position: 0) }

      before do
        visit project_boards_path(project)
      end

      it 'removes issues milestone when removing from the board' do
        wait_for_requests

        first('.card .card-number').click

        click_button('Remove from board')
        wait_for_requests

        expect(issue.reload.milestone).to be_nil
      end
    end

    xcontext 'new issues' do
      let(:label) { create(:label, project: project) }
      let!(:list1) { create(:list, board: board, label: label, position: 0) }
      let!(:board) { create(:board, project: project, milestone: milestone) }
      let!(:issue) { create(:issue, project: project) }

      before do
        visit project_boards_path(project)
      end

      it 'creates new issue with boards milestone' do
        wait_for_requests

        page.within(first('.board')) do
          find('.btn-default').click

          find('.form-control').set('testing new issue with milestone')

          click_button('Submit issue')

          wait_for_requests

          click_link('testing new issue with milestone')
        end

        expect(page).to have_content(milestone.title)
      end

      it 'updates issue with milestone from add issues modal' do
        wait_for_requests

        click_button 'Add issues'

        page.within('.add-issues-modal') do
          card = find('.card', :first)
          expect(page).to have_selector('.card', count: 1)

          card.click

          click_button 'Add 1 issue'
        end

        click_link(issue.title)

        expect(page).to have_content(milestone.title)
      end
    end
  end

  xcontext 'with the feature disabled' do
    before do
      stub_licensed_features(issue_board_milestone: false)
      visit project_boards_path(project)
    end

    it "doesn't show the input when creating a board" do
      page.within '#js-multiple-boards-switcher' do
        find('.dropdown-menu-toggle').click

        click_link 'Create new board'

        # To make sure the form is shown
        expect(page).to have_selector('#board-new-name')

        expect(page).not_to have_button('Milestone')
      end
    end

    it "doesn't show the option to edit the milestone" do
      page.within '#js-multiple-boards-switcher' do
        find('.dropdown-menu-toggle').click

        # To make sure the dropdown is open
        expect(page).to have_link('Edit board name')

        expect(page).not_to have_link('Edit board milestone')
      end
    end
  end

  def create_board_with_milestone
    creating_new_board do
      find('.edit-link', match: :first).trigger('click')
      find('a', text: milestone.title).trigger('click')

      click_button 'Create'
    end
  end

  def create_board_with_labels
    creating_new_board do
      page.all('.edit-link')[1].trigger('click')
      find('a', text: label.title).trigger('click')

      click_button 'Create'
    end
  end

  def create_board_with_assignee
    creating_new_board do
      page.all('.edit-link')[2].trigger('click')
      find('a', text: user.name).trigger('click')

      click_button 'Create'
    end
  end

  def create_board_with_weight
    creating_new_board do
      page.all('.edit-link')[3].trigger('click')
      find('a', text: issue_with_weight.weight).trigger('click')

      click_button 'Create'
    end
  end

  def creating_new_board
    page.within '#js-multiple-boards-switcher' do
      find('.dropdown-menu-toggle').click

      click_link 'Create new board'

      find('#board-new-name').set 'test'

      click_button 'Expand'

      yield
    end
  end

  def update_board_milestone(milestone_title)
    page.within '#js-multiple-boards-switcher' do
      find('.dropdown-menu-toggle').click

      click_link 'Edit board milestone'

      click_link milestone_title

      click_button 'Save'
    end
  end
end
