# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for issues', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let!(:issue1) { create(:issue, title: 'issue Foo', project: project, created_at: 1.hour.ago) }
  let!(:issue2) { create(:issue, :closed, :confidential, title: 'issue Bar', project: project) }

  def search_for_issue(search)
    fill_in('dashboard_search', with: search)
    find('.btn-search').click
    select_search_scope('Issues')
  end

  context 'when signed in' do
    before do
      project.add_maintainer(user)
      sign_in(user)

      visit(search_path)
    end

    include_examples 'top right search form'
    include_examples 'search timeouts', 'issues'

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

      find('[data-testid="sort-highest-icon"]').click

      page.within('.results') do
        expect(page.all('.search-result-row').first).to have_link(issue1.title)
        expect(page.all('.search-result-row').last).to have_link(issue2.title)
      end
    end

    context 'when on a project page' do
      it 'finds an issue' do
        find('[data-testid="project-filter"]').click

        wait_for_requests

        page.within('[data-testid="project-filter"]') do
          click_on(project.name)
        end

        search_for_issue(issue1.title)

        page.within('.results') do
          expect(page).to have_link(issue1.title)
          expect(page).not_to have_link(issue2.title)
        end
      end
    end
  end

  context 'when signed out' do
    context 'when block_anonymous_global_searches is disabled' do
      let(:project) { create(:project, :public) }

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
      before do
        visit(search_path)
      end

      it 'is redirected to login page' do
        expect(page).to have_content('You must be logged in to search across all of GitLab')
      end
    end
  end
end
