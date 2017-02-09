require 'rails_helper'

describe 'Issue Boards', feature: true, js: true do
  include WaitForAjax
  include WaitForVueResource

  let(:user)         { create(:user) }
  let(:project)      { create(:empty_project, :public) }
  let!(:milestone)   { create(:milestone, project: project) }
  let!(:development) { create(:label, project: project, name: 'Development') }
  let!(:bug)         { create(:label, project: project, name: 'Bug') }
  let!(:regression)  { create(:label, project: project, name: 'Regression') }
  let!(:stretch)     { create(:label, project: project, name: 'Stretch') }
  let!(:issue1)      { create(:labeled_issue, project: project, assignee: user, milestone: milestone, labels: [development]) }
  let!(:issue2)      { create(:labeled_issue, project: project, labels: [development, stretch]) }
  let(:board)        { create(:board, project: project) }
  let!(:list)        { create(:list, board: board, label: development, position: 0) }

  before do
    project.team << [user, :master]

    login_as(user)

    visit namespace_project_board_path(project.namespace, project, board)
    wait_for_vue_resource
  end

  it 'shows sidebar when clicking issue' do
    page.within(first('.board')) do
      first('.card').click
    end

    expect(page).to have_selector('.issue-boards-sidebar')
  end

  it 'closes sidebar when clicking issue' do
    page.within(first('.board')) do
      first('.card').click
    end

    expect(page).to have_selector('.issue-boards-sidebar')

    page.within(first('.board')) do
      first('.card').click
    end

    expect(page).not_to have_selector('.issue-boards-sidebar')
  end

  it 'closes sidebar when clicking close button' do
    page.within(first('.board')) do
      first('.card').click
    end

    expect(page).to have_selector('.issue-boards-sidebar')

    find('.gutter-toggle').click

    expect(page).not_to have_selector('.issue-boards-sidebar')
  end

  it 'shows issue details when sidebar is open' do
    page.within(first('.board')) do
      first('.card').click
    end

    page.within('.issue-boards-sidebar') do
      expect(page).to have_content(issue2.title)
      expect(page).to have_content(issue2.to_reference)
    end
  end

  it 'removes card from board when clicking remove button' do
    page.within(first('.board')) do
      first('.card').click
    end

    page.within('.issue-boards-sidebar') do
      click_button 'Remove from board'
    end

    page.within(first('.board')) do
      expect(page).to have_selector('.card', count: 1)
    end
  end

  context 'assignee' do
    it 'updates the issues assignee' do
      page.within(first('.board')) do
        first('.card').click
      end

      page.within('.assignee') do
        click_link 'Edit'

        wait_for_ajax

        page.within('.dropdown-menu-user') do
          click_link user.name

          wait_for_vue_resource
        end

        expect(page).to have_content(user.name)
      end

      page.within(first('.board')) do
        page.within(first('.card')) do
          expect(page).to have_selector('.avatar')
        end
      end
    end

    it 'removes the assignee' do
      page.within(first('.board')) do
        find('.card:nth-child(2)').click
      end

      page.within('.assignee') do
        click_link 'Edit'

        wait_for_ajax

        page.within('.dropdown-menu-user') do
          click_link 'Unassigned'

          wait_for_vue_resource
        end

        expect(page).to have_content('No assignee')
      end

      page.within(first('.board')) do
        page.within(find('.card:nth-child(2)')) do
          expect(page).not_to have_selector('.avatar')
        end
      end
    end

    it 'assignees to current user' do
      page.within(first('.board')) do
        first('.card').click
      end

      page.within(find('.assignee')) do
        expect(page).to have_content('No assignee')

        click_link 'assign yourself'

        wait_for_vue_resource

        expect(page).to have_content(user.name)
      end

      page.within(first('.board')) do
        page.within(first('.card')) do
          expect(page).to have_selector('.avatar')
        end
      end
    end

    it 'resets assignee dropdown' do
      page.within(first('.board')) do
        first('.card').click
      end

      page.within('.assignee') do
        click_link 'Edit'

        wait_for_ajax

        page.within('.dropdown-menu-user') do
          click_link user.name

          wait_for_vue_resource
        end

        expect(page).to have_content(user.name)
      end

      page.within(first('.board')) do
        find('.card:nth-child(2)').click
      end

      page.within('.assignee') do
        click_link 'Edit'

        expect(page).not_to have_selector('.is-active')
      end
    end
  end

  context 'milestone' do
    it 'adds a milestone' do
      page.within(first('.board')) do
        first('.card').click
      end

      page.within('.milestone') do
        click_link 'Edit'

        wait_for_ajax

        click_link milestone.title

        wait_for_vue_resource

        page.within('.value') do
          expect(page).to have_content(milestone.title)
        end
      end
    end

    it 'removes a milestone' do
      page.within(first('.board')) do
        find('.card:nth-child(2)').click
      end

      page.within('.milestone') do
        click_link 'Edit'

        wait_for_ajax

        click_link "No Milestone"

        wait_for_vue_resource

        page.within('.value') do
          expect(page).not_to have_content(milestone.title)
        end
      end
    end
  end

  context 'due date' do
    it 'updates due date' do
      page.within(first('.board')) do
        first('.card').click
      end

      page.within('.due_date') do
        click_link 'Edit'

        click_button Date.today.day

        wait_for_vue_resource

        expect(page).to have_content(Date.today.to_s(:medium))
      end
    end
  end

  context 'labels' do
    it 'adds a single label' do
      page.within(first('.board')) do
        first('.card').click
      end

      page.within('.labels') do
        click_link 'Edit'

        wait_for_ajax

        click_link bug.title

        wait_for_vue_resource

        find('.dropdown-menu-close-icon').click

        page.within('.value') do
          expect(page).to have_selector('.label', count: 3)
          expect(page).to have_content(bug.title)
        end
      end

      page.within(first('.board')) do
        page.within(first('.card')) do
          expect(page).to have_selector('.label', count: 2)
          expect(page).to have_content(bug.title)
        end
      end
    end

    it 'adds a multiple labels' do
      page.within(first('.board')) do
        first('.card').click
      end

      page.within('.labels') do
        click_link 'Edit'

        wait_for_ajax

        click_link bug.title
        click_link regression.title

        wait_for_vue_resource

        find('.dropdown-menu-close-icon').click

        page.within('.value') do
          expect(page).to have_selector('.label', count: 4)
          expect(page).to have_content(bug.title)
          expect(page).to have_content(regression.title)
        end
      end

      page.within(first('.board')) do
        page.within(first('.card')) do
          expect(page).to have_selector('.label', count: 3)
          expect(page).to have_content(bug.title)
          expect(page).to have_content(regression.title)
        end
      end
    end

    it 'removes a label' do
      page.within(first('.board')) do
        first('.card').click
      end

      page.within('.labels') do
        click_link 'Edit'

        wait_for_ajax

        click_link stretch.title

        wait_for_vue_resource

        find('.dropdown-menu-close-icon').click

        page.within('.value') do
          expect(page).to have_selector('.label', count: 1)
          expect(page).not_to have_content(stretch.title)
        end
      end

      page.within(first('.board')) do
        page.within(first('.card')) do
          expect(page).not_to have_selector('.label')
          expect(page).not_to have_content(stretch.title)
        end
      end
    end
  end

  context 'subscription' do
    it 'changes issue subscription' do
      page.within(first('.board')) do
        first('.card').click
      end

      page.within('.subscription') do
        click_button 'Subscribe'
        wait_for_ajax
        expect(page).to have_content("Unsubscribe")
      end
    end
  end
end
