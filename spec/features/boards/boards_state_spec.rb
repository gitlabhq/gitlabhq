require 'rails_helper'

describe 'Issue Boards', feature: true, js: true do
  include WaitForVueResource
  include WaitForAjax

  let(:project) { create(:project_with_board, :public) }
  let(:user)    { create(:user) }

  before do
    project.team << [user, :master]

    login_as(user)
  end

  context 'state' do
    let!(:milestone)  { create(:milestone, project: project) }
    let(:planning)    { create(:label, project: project, name: 'Planning') }
    let!(:list1)      { create(:list, board: project.board, label: planning, position: 0) }
    let!(:issue1)     { create(:labeled_issue, :closed, project: project, labels: [planning], milestone: milestone, assignee: user, author: user) }
    let!(:issue2)     { create(:labeled_issue, project: project, labels: [planning]) }

    before do
      visit namespace_project_board_path(project.namespace, project)

      wait_for_vue_resource
    end

    it 'shows all opened issues' do
      page.within('.board:nth-child(2)') do
        expect(page).to have_selector('.card', count: 1)
        expect(first('.card')).to have_content(issue2.title)
      end
    end

    it 'shows all closed issues' do
      page.within('.issues-state-filters') do
        click_link 'Closed'
      end

      wait_for_vue_resource

      page.within('.board:nth-child(2)') do
        expect(page).to have_selector('.card', count: 1)
        expect(first('.card')).to have_content(issue1.title)
      end
    end

    it 'shows all issues' do
      page.within('.issues-state-filters') do
        click_link 'All'
      end

      wait_for_vue_resource

      page.within('.board:nth-child(2)') do
        expect(page).to have_selector('.card', count: 2)
      end
    end

    context 'filtering' do
      it 'filters assignee and state' do
        page.within '.issues-filters' do
          click_button('Assignee')
          wait_for_ajax

          page.within '.dropdown-menu-assignee' do
            click_link(user.name)
          end
          wait_for_vue_resource

          expect(find('.js-assignee-search')).to have_content(user.name)
        end

        page.within('.issues-state-filters') do
          click_link 'Closed'
        end

        page.within('.board:nth-child(2)') do
          expect(page).to have_selector('.card', count: 1)
          expect(first('.card')).to have_content(issue1.title)
        end
      end

      it 'filters milestone and state' do
        page.within '.issues-filters' do
          click_button('Milestone')
          wait_for_ajax

          page.within '.milestone-filter' do
            click_link(milestone.title)
          end
          wait_for_vue_resource

          expect(find('.js-milestone-select')).to have_content(milestone.title)
        end

        page.within('.issues-state-filters') do
          click_link 'Closed'
        end

        page.within('.board:nth-child(2)') do
          expect(page).to have_selector('.card', count: 1)
          expect(first('.card')).to have_content(issue1.title)
        end
      end

      it 'filters label and state' do
        page.within '.issues-filters' do
          click_button('Label')
          wait_for_ajax

          page.within '.dropdown-menu-labels' do
            click_link(planning.title)
            wait_for_vue_resource
            find('.dropdown-menu-close').click
          end
        end

        page.within('.issues-state-filters') do
          click_link 'Closed'
        end

        page.within('.board:nth-child(2)') do
          expect(page).to have_selector('.card', count: 1)
          expect(first('.card')).to have_content(issue1.title)
        end
      end
    end
  end
end
