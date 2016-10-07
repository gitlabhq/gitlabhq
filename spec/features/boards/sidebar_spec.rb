require 'rails_helper'

describe 'Issue Boards', feature: true, js: true do
  include WaitForAjax
  include WaitForVueResource

  let(:project)     { create(:project_with_board, :public) }
  let(:user)        { create(:user) }
  let!(:label)      { create(:label, project: project) }
  let!(:label2)     { create(:label, project: project) }
  let!(:milestone)  { create(:milestone, project: project) }
  let!(:issue2)     { create(:labeled_issue, project: project, assignee: user, milestone: milestone, labels: [label]) }
  let!(:issue)      { create(:issue, project: project) }

  before do
    project.team << [user, :master]

    login_as(user)

    visit namespace_project_board_path(project.namespace, project)
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
      expect(page).to have_content(issue.title)
      expect(page).to have_content(issue.to_reference)
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

      page.within('.assignee') do
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

        click_link Date.today.day

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

        click_link label.title

        wait_for_vue_resource

        find('.dropdown-menu-close-icon').click

        page.within('.value') do
          expect(page).to have_selector('.label', count: 1)
          expect(page).to have_content(label.title)
        end
      end

      page.within(first('.board')) do
        page.within(first('.card')) do
          expect(page).to have_selector('.label', count: 1)
          expect(page).to have_content(label.title)
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

        click_link label.title
        click_link label2.title

        wait_for_vue_resource

        find('.dropdown-menu-close-icon').click

        page.within('.value') do
          expect(page).to have_selector('.label', count: 2)
          expect(page).to have_content(label.title)
          expect(page).to have_content(label2.title)
        end
      end

      page.within(first('.board')) do
        page.within(first('.card')) do
          expect(page).to have_selector('.label', count: 2)
          expect(page).to have_content(label.title)
          expect(page).to have_content(label2.title)
        end
      end
    end

    it 'removes a label' do
      page.within(first('.board')) do
        find('.card:nth-child(2)').click
      end

      page.within('.labels') do
        click_link 'Edit'

        wait_for_ajax

        click_link label.title

        wait_for_vue_resource

        find('.dropdown-menu-close-icon').click

        page.within('.value') do
          expect(page).to have_selector('.label', count: 0)
          expect(page).not_to have_content(label.title)
        end
      end

      page.within(first('.board')) do
        page.within(find('.card:nth-child(2)')) do
          expect(page).not_to have_selector('.label', count: 1)
          expect(page).not_to have_content(label.title)
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

        expect(page).to have_content("You're receiving notifications because you're subscribed to this thread.")
      end
    end
  end
end
