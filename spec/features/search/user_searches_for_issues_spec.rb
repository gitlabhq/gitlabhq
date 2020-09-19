# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for issues', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let!(:issue1) { create(:issue, title: 'Foo', project: project) }
  let!(:issue2) { create(:issue, :closed, :confidential, title: 'Bar', project: project) }

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

    context 'when on a project page' do
      it 'finds an issue' do
        find('.js-search-project-dropdown').click

        page.within('.project-filter') do
          click_link(project.full_name)
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
