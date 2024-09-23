# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard Todos', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user, username: 'john') }
  let_it_be(:user2) { create(:user, username: 'diane') }
  let_it_be(:author) { create(:user) }
  let_it_be(:project) { create(:project, :public, developers: user) }
  let_it_be(:issue) { create(:issue, project: project, due_date: Date.today, title: "Fix bug") }

  context 'when user does not have todos' do
    before do
      sign_in(user)
      visit dashboard_todos_path
    end

    it 'passes axe automated accessibility testing' do
      expect(page).to be_axe_clean.within('#content-body')
    end
  end

  context 'when user has todos' do
    before do
      allow(Todo).to receive(:default_per_page).and_return(2)
      mr_merged = create(:merge_request, :simple, :merged, author: user, source_project: project)
      note = create(
        :note,
        project: project,
        note: "Check out #{mr_merged.to_reference}",
        noteable: create(:issue, project: project)
      )

      create(:todo, :assigned, user: user, project: project, target: issue, author: user2)
      create(:todo, :mentioned, user: user, project: project, target: mr_merged, author: author)
      create(:todo, :mentioned, project: project, target: issue, user: user, note_id: note.id)

      sign_in(user)
      visit dashboard_todos_path
    end

    it 'passes axe automated accessibility testing' do
      expect(page).to be_axe_clean.within('#content-body')
    end

    context 'when user has the option to undo delete action' do
      before do
        within first('.todo') do
          find_by_testid('check-icon').click
        end
      end

      it 'passes axe automated accessibility testing' do
        expect(page).to be_axe_clean.within('#content-body')
      end
    end

    context 'and filters with search options' do
      it 'passes axe automated accessibility testing' do
        click_button 'Author'
        expect(page).to be_axe_clean.within('.todos-filters')
      end
    end

    context 'and filters with list options' do
      it 'passes axe automated accessibility testing' do
        click_button 'Action'
        expect(page).to be_axe_clean.within('.todos-filters')
      end
    end

    context 'and sorts the list' do
      it 'passes axe automated accessibility testing' do
        click_button 'Last created'
        expect(page).to be_axe_clean.within('.todos-filters')
      end
    end
  end

  context 'when user has todos marked as done' do
    before do
      create(:todo, :mentioned, :done, user: user, project: project, target: issue, author: author)
      sign_in(user)
      visit dashboard_todos_path(state: :done)
    end

    it 'passes axe automated accessibility testing' do
      expect(page).to be_axe_clean.within('#content-body')
    end
  end
end
