# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for merge requests', :js, :clean_gitlab_redis_rate_limiting, feature_category: :global_search do
  include ListboxHelpers
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }
  let_it_be(:merge_request1) { create(:merge_request, title: 'Merge Request Foo', source_project: project, target_project: project, created_at: 1.hour.ago) }
  let_it_be(:merge_request2) { create(:merge_request, :simple, title: 'Merge Request Bar', source_project: project, target_project: project) }

  def search_for_mr(search)
    submit_dashboard_search(search)
    select_search_scope('Merge requests')
  end

  before do
    sign_in(user)

    visit(search_path)
  end

  include_examples 'top right search form'
  include_examples 'search timeouts', 'merge_requests'

  it 'shows scopes when there is no search term' do
    submit_dashboard_search('')

    within_testid('search-filter') do
      expect(page).to have_selector('[data-testid="nav-item"]', minimum: 5)
    end
  end

  it 'finds a merge request' do
    search_for_mr(merge_request1.title)

    page.within('.results') do
      expect(page).to have_link(merge_request1.title)
      expect(page).not_to have_link(merge_request2.title)

      # Each result should have MR refs like `gitlab-org/gitlab!1`
      page.all('.search-result-row').each do |e|
        expect(e.text).to match(/!\d+/)
      end
    end
  end

  it 'sorts by created date' do
    search_for_mr('Merge Request')

    page.within('.results') do
      expect(page.all('.search-result-row').first).to have_link(merge_request2.title)
      expect(page.all('.search-result-row').last).to have_link(merge_request1.title)
    end

    find_by_testid('sort-highest-icon').click

    page.within('.results') do
      expect(page.all('.search-result-row').first).to have_link(merge_request1.title)
      expect(page.all('.search-result-row').last).to have_link(merge_request2.title)
    end
  end

  context 'when on a project page' do
    it 'finds a merge request' do
      find_by_testid('project-filter').click

      wait_for_requests

      within_testid('project-filter') do
        select_listbox_item project.name
      end

      search_for_mr(merge_request1.title)

      page.within('.results') do
        expect(page).to have_link(merge_request1.title)
        expect(page).not_to have_link(merge_request2.title)
      end
    end
  end
end
