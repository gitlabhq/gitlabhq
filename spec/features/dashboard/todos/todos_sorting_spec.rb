# frozen_string_literal: true

# covered by ./accessibility_spec.rb

require 'spec_helper'

RSpec.describe 'Dashboard > User sorts todos', :js, feature_category: :notifications do
  let_it_be(:user)    { create(:user) }
  let_it_be(:project) { create(:project) }

  let_it_be(:label_1) { create(:label, title: 'label_1', project: project, priority: 1) }
  let_it_be(:label_2) { create(:label, title: 'label_2', project: project, priority: 2) }
  let_it_be(:label_3) { create(:label, title: 'label_3', project: project, priority: 3) }

  before_all do
    project.add_developer(user)
  end

  context 'sort options' do
    let_it_be(:issue_1) { create(:issue, title: 'issue_1', project: project) }
    let_it_be(:issue_2) { create(:issue, title: 'issue_2', project: project) }
    let_it_be(:issue_3) { create(:issue, title: 'issue_3', project: project) }
    let_it_be(:issue_4) { create(:issue, title: 'issue_4', project: project) }

    let_it_be(:merge_request_1) { create(:merge_request, source_project: project, title: 'merge_request_1') }

    before do
      create(:todo, user: user, project: project, target: issue_4, created_at: 5.hours.ago, updated_at: 5.hours.ago)
      create(:todo, user: user, project: project, target: issue_2, created_at: 4.hours.ago, updated_at: 4.hours.ago)
      create(:todo, user: user, project: project, target: issue_3, created_at: 3.hours.ago, updated_at: 2.minutes.ago)
      create(:todo, user: user, project: project, target: issue_1, created_at: 2.hours.ago, updated_at: 2.hours.ago)
      create(
        :todo, user: user, project: project, target: merge_request_1, created_at: 1.hour.ago, updated_at: 1.hour.ago
      )

      merge_request_1.labels << label_1
      issue_3.labels         << label_1
      issue_2.labels         << label_3
      issue_1.labels         << label_2

      sign_in(user)
      visit dashboard_todos_path
    end

    it 'updates sort order and direction' do
      # Default order is created_at DESC
      results_list = page.find('ol[data-testid="todo-item-list"]')
      expect(results_list.all('[data-testid=todo-title]')[0]).to have_content('merge_request_1')
      expect(results_list.all('[data-testid=todo-title]')[1]).to have_content('issue_1')
      expect(results_list.all('[data-testid=todo-title]')[2]).to have_content('issue_3')
      expect(results_list.all('[data-testid=todo-title]')[3]).to have_content('issue_2')
      expect(results_list.all('[data-testid=todo-title]')[4]).to have_content('issue_4')

      # Switch order to created_at ASC
      click_on_sort_direction
      results_list = page.find('ol[data-testid="todo-item-list"]')
      expect(results_list.all('[data-testid=todo-title]')[0]).to have_content('issue_4')
      expect(results_list.all('[data-testid=todo-title]')[1]).to have_content('issue_2')
      expect(results_list.all('[data-testid=todo-title]')[2]).to have_content('issue_3')
      expect(results_list.all('[data-testid=todo-title]')[3]).to have_content('issue_1')
      expect(results_list.all('[data-testid=todo-title]')[4]).to have_content('merge_request_1')

      # Change direction to 'Label priority' ASC
      click_on_sort_order 'Label priority'
      results_list = page.find('ol[data-testid="todo-item-list"]')
      expect(results_list.all('[data-testid=todo-title]')[0]).to have_content('issue_3')
      expect(results_list.all('[data-testid=todo-title]')[1]).to have_content('merge_request_1')
      expect(results_list.all('[data-testid=todo-title]')[2]).to have_content('issue_1')
      expect(results_list.all('[data-testid=todo-title]')[3]).to have_content('issue_2')
      expect(results_list.all('[data-testid=todo-title]')[4]).to have_content('issue_4')

      # Change direction to updated_at DESC
      click_on_sort_order 'Updated'
      click_on_sort_direction
      results_list = page.find('ol[data-testid="todo-item-list"]')
      expect(results_list.all('[data-testid=todo-title]')[0]).to have_content('issue_3')
      expect(results_list.all('[data-testid=todo-title]')[1]).to have_content('merge_request_1')
      expect(results_list.all('[data-testid=todo-title]')[2]).to have_content('issue_1')
      expect(results_list.all('[data-testid=todo-title]')[3]).to have_content('issue_2')
      expect(results_list.all('[data-testid=todo-title]')[4]).to have_content('issue_4')
    end

    def click_on_sort_order(text)
      find('[data-testid=todos-sorting] [data-testid=base-dropdown-toggle]').click
      find('li', text: text).click
    end

    def click_on_sort_direction
      find('.sorting-direction-button').click
    end
  end

  context 'issues and merge requests' do
    let(:issue_1) { create(:issue, id: 10000, title: 'issue_1', project: project) }
    let(:issue_2) { create(:issue, id: 10001, title: 'issue_2', project: project) }
    let(:merge_request_1) { create(:merge_request, id: 10000, title: 'merge_request_1', source_project: project) }

    before do
      issue_1.labels << label_1
      issue_2.labels << label_2

      create(:todo, user: user, project: project, target: issue_1)
      create(:todo, user: user, project: project, target: issue_2)
      create(:todo, user: user, project: project, target: merge_request_1)

      sign_in(user)
      visit dashboard_todos_path(sort: 'LABEL_PRIORITY_ASC')
    end

    it "doesn't mix issues and merge requests label priorities" do
      results_list = page.find('ol[data-testid="todo-item-list"]')
      expect(results_list.all('[data-testid=todo-title]')[0]).to have_content('issue_1')
      expect(results_list.all('[data-testid=todo-title]')[1]).to have_content('issue_2')
      expect(results_list.all('[data-testid=todo-title]')[2]).to have_content('merge_request_1')
    end
  end
end
