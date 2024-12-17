# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for commits', :js, :clean_gitlab_redis_rate_limiting, feature_category: :global_search do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:sha) { '6d394385cf567f80a8fd85055db1ab4c5295806f' }

  before do
    project.add_reporter(user)
    sign_in(user)

    visit(search_path(project_id: project.id))
  end

  include_examples 'search timeouts', 'commits' do
    let(:additional_params) { { project_id: project.id } }
  end

  it 'shows scopes when there is no search term' do
    submit_dashboard_search('')

    within_testid('search-filter') do
      expect(page).to have_selector('[data-testid="nav-item"]', minimum: 5)
    end
  end

  context 'when searching by SHA' do
    it 'finds a commit and redirects to its page' do
      submit_search(sha)

      expect(page).to have_current_path(project_commit_path(project, sha))
    end

    it 'finds a commit in uppercase and redirects to its page' do
      submit_search(sha.upcase)

      expect(page).to have_current_path(project_commit_path(project, sha))
    end
  end

  context 'when searching by message' do
    it 'finds a commit and holds on /search page' do
      project.repository.commit_files(
        user,
        message: 'Message referencing another sha: "deadbeef"',
        branch_name: 'master',
        actions: [{ action: :create, file_path: 'a/new.file', contents: 'new file' }]
      )

      submit_search('deadbeef')

      expect(page).to have_current_path('/search', ignore_query: true)
    end

    it 'finds multiple commits' do
      submit_search('See merge request')
      select_search_scope('Commits')

      expect(page).to have_selector('.commit-detail', visible: false, count: 9)
    end
  end
end
