# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues > User sees empty state', :js, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { project.creator }

  shared_examples_for 'empty state with filters' do
    it 'user sees empty state with filters' do
      create(:issue, author: user, project: project)

      visit project_issues_path(project, milestone_title: "1.0")

      expect(page).to have_content('No results found')
      expect(page).to have_content('Edit your search and try again.')
    end
  end

  describe 'while user is signed out' do
    describe 'empty state' do
      it 'user sees empty state' do
        visit project_issues_path(project)

        expect(page).to have_content('Use issues to collaborate on ideas, solve problems, and plan work')
        expect(page).to have_content('Learn more about issues.')
        expect(page).to have_content('Register / Sign In')
      end

      it_behaves_like 'empty state with filters'
    end
  end

  describe 'while user is signed in' do
    before do
      sign_in(user)
    end

    describe 'empty state' do
      it 'user sees empty state' do
        visit project_issues_path(project)

        expect(page).to have_content('Use issues to collaborate on ideas, solve problems, and plan work')
        expect(page).to have_content('Learn more about issues.')
        expect(page).to have_content('New issue')
      end

      it_behaves_like 'empty state with filters'
    end
  end
end
