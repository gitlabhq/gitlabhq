# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for issues', :js, :clean_gitlab_redis_rate_limiting, feature_category: :global_search do
  include ListboxHelpers
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }

  let!(:issue1) { create(:issue, title: 'issue Foo', project: project, created_at: 1.hour.ago) }
  let!(:issue2) { create(:issue, :closed, :confidential, title: 'issue Bar', project: project) }

  def search_for_issue(search)
    submit_dashboard_search(search)
    select_search_scope('Issue')
  end

  context 'when signed in' do
    before do
      project.add_maintainer(user)
      sign_in(user)

      visit(search_path)
    end

    include_examples 'top right search form'

    context 'when search times out' do
      before do
        allow_next_instance_of(SearchService) do |service|
          allow(service).to receive(:search_results).and_raise(ActiveRecord::QueryCanceled)
        end

        visit(search_path(search: 'test', scope: 'issues', type: 'issue'))
      end

      it 'renders timeout information' do
        expect(page).to have_content('Your search has timed out')
      end

      it 'sets tab count to 0' do
        expect(find_by_testid('search-filter').find('[aria-current="page"]')).to have_text('Issue')
      end
    end

    it 'finds an issue' do
      search_for_issue(issue1.title)

      page.within('.results') do
        expect(page).to have_link(issue1.title)
        expect(page).not_to have_link(issue2.title)
      end
    end

    it 'hides confidential icon for non-confidential issues' do
      search_for_issue(issue1.title)

      page.within('.results') do
        expect(page).not_to have_css('[data-testid="eye-slash-icon"]')
      end
    end

    it 'shows confidential icon for confidential issues' do
      search_for_issue(issue2.title)

      page.within('.results') do
        expect(page).to have_css('[data-testid="eye-slash-icon"]')
      end
    end

    it 'shows correct badge for open issues' do
      search_for_issue(issue1.title)

      page.within('.results') do
        expect(page).to have_css('.badge-success')
        expect(page).not_to have_css('.badge-info')
      end
    end

    it 'shows correct badge for closed issues' do
      search_for_issue(issue2.title)

      page.within('.results') do
        expect(page).not_to have_css('.badge-success')
        expect(page).to have_css('.badge-info')
      end
    end

    it 'sorts by created date' do
      search_for_issue('issue')

      page.within('.results') do
        expect(page.all('.search-result-row').first).to have_link(issue2.title)
        expect(page.all('.search-result-row').last).to have_link(issue1.title)
      end

      find_by_testid('sort-highest-icon').click

      page.within('.results') do
        expect(page.all('.search-result-row').first).to have_link(issue1.title)
        expect(page.all('.search-result-row').last).to have_link(issue2.title)
      end
    end

    context 'when on a project page' do
      it 'finds an issue' do
        find_by_testid('project-filter').click

        wait_for_requests

        within_testid('project-filter') do
          select_listbox_item project.name
        end

        search_for_issue(issue1.title)

        page.within('.results') do
          expect(page).to have_link(issue1.title)
          expect(page).not_to have_link(issue2.title)
        end
      end
    end

    it 'shows scopes when there is no search term' do
      search_for_issue('')

      within_testid('search-filter') do
        expect(page).to have_selector('[data-testid="nav-item"]', minimum: 5)
      end
    end
  end

  context 'when signed out' do
    context 'when block_anonymous_global_searches is disabled' do
      let_it_be(:project) { create(:project, :public) }

      before do
        stub_feature_flags(block_anonymous_global_searches: false)

        visit(search_path)
      end

      include_examples 'top right search form'

      it 'finds an issue' do
        search_for_issue(issue1.title)

        page.within('.results') do
          expect(page).to have_link(issue1.title)
          expect(page).not_to have_link(issue2.title)
        end
      end
    end

    context 'when block_anonymous_global_searches is enabled' do
      it 'is redirected to login page' do
        visit(search_path)

        expect(page).to have_content('You need to sign in or sign up before continuing.')
      end
    end
  end
end
