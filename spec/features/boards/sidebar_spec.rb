require 'rails_helper'

describe 'Issue Boards', js: true do
  let(:user)         { create(:user) }
  let(:user2)        { create(:user) }
  let(:project)      { create(:empty_project, :public) }
  let!(:milestone)   { create(:milestone, project: project) }
  let!(:development) { create(:label, project: project, name: 'Development') }
  let!(:bug)         { create(:label, project: project, name: 'Bug') }
  let!(:regression)  { create(:label, project: project, name: 'Regression') }
  let!(:stretch)     { create(:label, project: project, name: 'Stretch') }
  let!(:issue1)      { create(:labeled_issue, project: project, assignees: [user], milestone: milestone, labels: [development], relative_position: 2) }
  let!(:issue2)      { create(:labeled_issue, project: project, labels: [development, stretch], relative_position: 1) }
  let(:board)        { create(:board, project: project) }
  let!(:list)        { create(:list, board: board, label: development, position: 0) }
  let(:card) { find('.board:nth-child(2)').first('.card') }

  before do
    Timecop.freeze
    stub_licensed_features(multiple_issue_assignees: false)

    project.team << [user, :master]

    sign_in(user)

    visit project_board_path(project, board)
    wait_for_requests
  end

  after do
    Timecop.return
  end

  it 'shows sidebar when clicking issue' do
    click_card(card)

    expect(page).to have_selector('.issue-boards-sidebar')
  end

  it 'closes sidebar when clicking issue' do
    click_card(card)

    expect(page).to have_selector('.issue-boards-sidebar')

    click_card(card)

    expect(page).not_to have_selector('.issue-boards-sidebar')
  end

  it 'closes sidebar when clicking close button' do
    click_card(card)

    expect(page).to have_selector('.issue-boards-sidebar')

    find('.gutter-toggle').trigger('click')

    expect(page).not_to have_selector('.issue-boards-sidebar')
  end

  it 'shows issue details when sidebar is open' do
    click_card(card)

    page.within('.issue-boards-sidebar') do
      expect(page).to have_content(issue2.title)
      expect(page).to have_content(issue2.to_reference)
    end
  end

  it 'removes card from board when clicking ' do
    click_card(card)

    page.within('.issue-boards-sidebar') do
      click_button 'Remove from board'
    end

    wait_for_requests

    page.within(find('.board:nth-child(2)')) do
      expect(page).to have_selector('.card', count: 1)
    end
  end

  it 'does not show remove button for backlog or closed issues' do
    create(:issue, project: project)
    create(:issue, :closed, project: project)

    visit project_board_path(project, board)
    wait_for_requests

    click_card(find('.board:nth-child(1)').first('.card'))

    expect(find('.issue-boards-sidebar')).not_to have_button 'Remove from board'

    click_card(find('.board:nth-child(3)').first('.card'))

    expect(find('.issue-boards-sidebar')).not_to have_button 'Remove from board'
  end

  context 'assignee' do
    it 'updates the issues assignee' do
      click_card(card)

      page.within('.assignee') do
        click_link 'Edit'

        wait_for_requests

        page.within('.dropdown-menu-user') do
          click_link user.name

          wait_for_requests
        end

        expect(page).to have_content(user.name)
      end

      expect(card).to have_selector('.avatar')
    end

    it 'removes the assignee' do
      card_two = find('.board:nth-child(2)').find('.card:nth-child(2)')
      click_card(card_two)

      page.within('.assignee') do
        click_link 'Edit'

        wait_for_requests

        page.within('.dropdown-menu-user') do
          click_link 'Unassigned'
        end

        wait_for_requests

        expect(page).to have_content('No assignee')
      end

      expect(card_two).not_to have_selector('.avatar')
    end

    it 'assignees to current user' do
      click_card(card)

      page.within(find('.assignee')) do
        expect(page).to have_content('No assignee')

        click_button 'assign yourself'

        wait_for_requests

        expect(page).to have_content(user.name)
      end

      expect(card).to have_selector('.avatar')
    end

    it 'updates assignee dropdown' do
      click_card(card)

      page.within('.assignee') do
        click_link 'Edit'

        wait_for_requests

        page.within('.dropdown-menu-user') do
          click_link user.name

          wait_for_requests
        end

        expect(page).to have_content(user.name)
      end

      page.within(find('.board:nth-child(2)')) do
        find('.card:nth-child(2)').trigger('click')
      end

      page.within('.assignee') do
        click_link 'Edit'

        expect(find('.dropdown-menu')).to have_selector('.is-active')
      end
    end
  end

  context 'milestone' do
    it 'adds a milestone' do
      click_card(card)

      page.within('.milestone') do
        click_link 'Edit'

        wait_for_requests

        click_link milestone.title

        wait_for_requests

        page.within('.value') do
          expect(page).to have_content(milestone.title)
        end
      end
    end

    it 'removes a milestone' do
      click_card(card)

      page.within('.milestone') do
        click_link 'Edit'

        wait_for_requests

        click_link "No Milestone"

        wait_for_requests

        page.within('.value') do
          expect(page).not_to have_content(milestone.title)
        end
      end
    end
  end

  context 'due date' do
    it 'updates due date' do
      click_card(card)

      page.within('.due_date') do
        click_link 'Edit'

        click_button Date.today.day

        wait_for_requests

        expect(page).to have_content(Date.today.to_s(:medium))
      end
    end
  end

  context 'labels' do
    it 'adds a single label' do
      click_card(card)

      page.within('.labels') do
        click_link 'Edit'

        wait_for_requests

        click_link bug.title

        wait_for_requests

        find('.dropdown-menu-close-icon').click

        page.within('.value') do
          expect(page).to have_selector('.label', count: 3)
          expect(page).to have_content(bug.title)
        end
      end

      expect(card).to have_selector('.label', count: 2)
      expect(card).to have_content(bug.title)
    end

    it 'adds a multiple labels' do
      click_card(card)

      page.within('.labels') do
        click_link 'Edit'

        wait_for_requests

        click_link bug.title
        click_link regression.title

        wait_for_requests

        find('.dropdown-menu-close-icon').click

        page.within('.value') do
          expect(page).to have_selector('.label', count: 4)
          expect(page).to have_content(bug.title)
          expect(page).to have_content(regression.title)
        end
      end

      expect(card).to have_selector('.label', count: 3)
      expect(card).to have_content(bug.title)
      expect(card).to have_content(regression.title)
    end

    it 'removes a label' do
      click_card(card)

      page.within('.labels') do
        click_link 'Edit'

        wait_for_requests

        click_link stretch.title

        wait_for_requests

        find('.dropdown-menu-close-icon').click

        page.within('.value') do
          expect(page).to have_selector('.label', count: 1)
          expect(page).not_to have_content(stretch.title)
        end
      end

      expect(card).not_to have_selector('.label')
      expect(card).not_to have_content(stretch.title)
    end
  end

  context 'subscription' do
    it 'changes issue subscription' do
      click_card(card)

      page.within('.subscription') do
        click_button 'Subscribe'
        wait_for_requests
        expect(page).to have_content("Unsubscribe")
      end
    end
  end

  def click_card(card)
    page.within(card) do
      first('.card-number').click
    end

    wait_for_sidebar
  end

  def wait_for_sidebar
    # loop until the CSS transition is complete
    Timeout.timeout(0.5) do
      loop until evaluate_script('$(".right-sidebar").outerWidth()') == 290
    end
  end
end
