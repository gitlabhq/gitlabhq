# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for comments', :js, :disable_rate_limiter, feature_category: :global_search do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_reporter(user)
    sign_in(user)

    visit(project_path(project))
  end

  include_examples 'search timeouts', 'notes' do
    let(:additional_params) { { project_id: project.id } }
  end

  context 'when a comment is in commits' do
    context 'when comment belongs to an invalid commit' do
      let(:comment) { create(:note_on_commit, author: user, project: project, commit_id: 12345678, note: 'Bug here') }

      it 'finds a commit' do
        submit_search(comment.note)
        select_search_scope('Comments')

        page.within('.results') do
          expect(page).to have_content('Commit deleted')
          expect(page).to have_content('12345678')
        end
      end
    end
  end

  it 'shows scopes when there is no search term' do
    submit_dashboard_search('')

    within_testid('search-filter') do
      expect(page).to have_selector('[data-testid="nav-item"]', minimum: 5)
    end
  end

  context 'when a comment is in a snippet' do
    let(:snippet) { create(:project_snippet, :private, project: project, author: user, title: 'Some title') }
    let(:comment) { create(:note, noteable: snippet, author: user, note: 'Supercalifragilisticexpialidocious', project: project) }

    it 'finds a snippet' do
      submit_search(comment.note)
      select_search_scope('Comments')

      expect(page).to have_selector('.results', text: snippet.title)
    end
  end
end
