# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues > User sees empty state', :js, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { project.creator }

  shared_examples_for 'empty state with filters' do
    it 'user sees empty state with filters' do
      create(:issue, author: user, project: project)

      visit project_work_items_path(project, milestone_title: "1.0")

      expect(page).to have_content('No results found')
      expect(page).to have_content('To widen your search, change or remove filters above.')
    end
  end

  describe 'while user is signed out' do
    describe 'empty state' do
      it 'user sees empty state' do
        visit project_work_items_path(project)

        expect(page).to have_content('Track bugs, plan features, and organize your work with issues')
        expect(page).to have_content('Register / Sign In')
      end

      it_behaves_like 'empty state with filters'
    end
  end

  describe 'while user is signed in' do
    before do
      create(:callout, user: user, feature_name: :work_items_onboarding_modal)
      sign_in(user)
    end

    describe 'empty state' do
      it 'user sees empty state' do
        visit project_work_items_path(project)

        expect(page).to have_content('Track bugs, plan features, and organize your efforts with work items')
        expect(page).to have_link('New item')
      end

      it_behaves_like 'empty state with filters'
    end
  end
end
