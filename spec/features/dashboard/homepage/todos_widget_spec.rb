# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Home - Todos', :js, feature_category: :notifications do
  let_it_be(:user) { create(:user, :with_namespace) }

  before do
    stub_feature_flags(personal_homepage: true)
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
  end
end
