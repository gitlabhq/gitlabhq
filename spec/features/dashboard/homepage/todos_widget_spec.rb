# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Home - Todos', :js, feature_category: :notifications do
  let_it_be(:user) { create(:user, :with_namespace) }

  before do
    sign_in user
  end

  context 'with no undone todos' do
    it 'shows a message' do
      visit home_dashboard_path
      expect(page).to have_content("All your to-do items are done.")
    end
  end

  context 'with undone todos' do
    let_it_be(:project) { create(:project, :public, :repository) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project, title: 'Foo MR') }
    let_it_be(:todo) { create(:todo, target: merge_request, project: project, user: user) }

    it 'shows the todos' do
      visit home_dashboard_path
      within_testid('homepage-todos-widget') do
        expect(page).to have_content(todo.target.title)
      end
    end

    context 'when marking a to-do as done' do
      let_it_be(:other_merge_request) do
        create(:merge_request, source_project: project, source_branch: 'improve/awesome', title: 'Bar MR')
      end

      let_it_be(:other_todo) do
        create(:todo, target: other_merge_request, project: project, user: user)
      end

      # Regression test for https://gitlab.com/gitlab-org/gitlab/-/merge_requests/257236. Feature specs
      # enable all feature flags, so the sidebar/topbar use Vue 3 (vue3_migrate_super_sidebar) while the
      # homepage app stays Vue 2, running both Vue runtimes on one page. user_counts_manager.js was
      # compiled once per Vue lane and each copy added a `todo:toggle` listener, so marking a to-do done
      # decremented the shared count twice.
      it 'decrements the topbar to-do count by exactly one', :use_clean_rails_memory_store_caching do
        # Warm the cached MR counts so the page doesn't fetch /user_counts on load. That fetch can
        # resolve after the click and restore the old to-do count.
        user.all_assigned_merge_requests_count
        user.review_requested_open_merge_requests_count

        visit home_dashboard_path

        expect(page).to have_css('[data-gitlab-vue3-app="SuperTopbarRoot"]')
        within_testid('todos-shortcut-button') do
          expect(page).to have_text('2')
        end

        within_testid('homepage-todos-widget') do
          first_todo_item = find("[data-testid^='todo-item-']", match: :first)
          within(first_todo_item) do
            click_button 'Mark as done'
          end
        end

        within_testid('todos-shortcut-button') do
          expect(page).to have_text('1')
        end
      end
    end
  end
end
