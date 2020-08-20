# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues > User sees empty state', :js do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { project.creator }

  shared_examples_for 'empty state with filters' do
    it 'user sees empty state with filters' do
      create(:issue, author: user, project: project)

      visit project_issues_path(project, milestone_title: "1.0")

      expect(page).to have_content('Sorry, your filter produced no results')
      expect(page).to have_content('To widen your search, change or remove filters above')
    end
  end

  describe 'while user is signed out' do
    describe 'empty state' do
      it 'user sees empty state' do
        visit project_issues_path(project)

        expect(page).to have_content('Register / Sign In')
        expect(page).to have_content('The Issue Tracker is the place to add things that need to be improved or solved in a project.')
        expect(page).to have_content('You can register or sign in to create issues for this project.')
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

        expect(page).to have_content('The Issue Tracker is the place to add things that need to be improved or solved in a project')
        expect(page).to have_content('Issues can be bugs, tasks or ideas to be discussed. Also, issues are searchable and filterable.')
        expect(page).to have_content('New issue')
      end

      it_behaves_like 'empty state with filters'
    end
  end
end
