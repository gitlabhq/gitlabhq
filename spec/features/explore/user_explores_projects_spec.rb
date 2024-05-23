# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User explores projects', feature_category: :user_profile do
  shared_examples 'an "Explore > Projects" page with sidebar and breadcrumbs' do |page_path, params|
    before do
      visit send(page_path, params)
    end

    describe "sidebar", :js do
      it 'shows the "Explore" sidebar' do
        has_testid?('super-sidebar')
        within_testid('super-sidebar') do
          expect(page).to have_css('#super-sidebar-context-header', text: 'Explore')
        end
      end

      it 'shows the "Projects" menu item as active' do
        within_testid('super-sidebar') do
          expect(page).to have_css("[aria-current='page']", text: "Projects")
        end
      end
    end

    describe 'breadcrumbs', :js do
      it 'has "Explore" as its root breadcrumb' do
        within_testid('breadcrumb-links') do
          expect(find('li:first-of-type')).to have_link('Explore', href: explore_root_path)
        end
      end
    end
  end

  describe '"All" tab' do
    it_behaves_like(
      'an "Explore > Projects" page with sidebar and breadcrumbs',
      :explore_projects_path,
      { archived: 'true' }
    )
  end

  describe '"Most starred" tab' do
    it_behaves_like 'an "Explore > Projects" page with sidebar and breadcrumbs', :starred_explore_projects_path
  end

  describe '"Trending" tab' do
    it_behaves_like 'an "Explore > Projects" page with sidebar and breadcrumbs', :trending_explore_projects_path
  end

  context 'when some projects exist' do
    let_it_be(:archived_project) { create(:project, :archived) }
    let_it_be(:internal_project) { create(:project, :internal) }
    let_it_be(:private_project) { create(:project, :private) }
    let_it_be(:public_project) { create(:project, :public) }

    context 'when not signed in' do
      context 'when viewing public projects' do
        before do
          visit(explore_projects_path)
        end

        include_examples 'shows public projects'
      end

      context 'when visibility is restricted to public' do
        before do
          stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
          visit(explore_projects_path)
        end

        it 'redirects to login page' do
          expect(page).to have_current_path(new_user_session_path)
        end
      end
    end

    context 'when signed in' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      shared_examples 'empty search results' do
        it 'shows correct empty state message', :js do
          search('zzzzzzzzzzzzzzzzzzz')

          expect(page).to have_content('Explore public groups to find projects to contribute to')
        end
      end

      shared_examples 'minimum search length' do
        it 'shows a prompt to enter a longer search term', :js do
          search('z')

          expect(page).to have_content('Enter at least three characters to search')
        end
      end

      context 'when viewing public projects' do
        before do
          visit(explore_projects_path)
        end

        include_examples 'shows public and internal projects'
        include_examples 'empty search results'
        include_examples 'minimum search length'
      end

      context 'when viewing most starred projects' do
        before do
          visit(starred_explore_projects_path)
        end

        include_examples 'shows public and internal projects'
        include_examples 'empty search results'
        include_examples 'minimum search length'
      end

      context 'when viewing trending projects' do
        before do
          [archived_project, public_project].each { |project| create(:note_on_issue, project: project) }

          TrendingProject.refresh!

          visit(trending_explore_projects_path)
        end

        include_examples 'shows public projects'
        include_examples 'empty search results'
        include_examples 'minimum search length'
      end
    end
  end

  context 'when there are no projects' do
    shared_examples 'explore page empty state' do
      it 'shows correct empty state message' do
        expect(page).to have_content('Explore public groups to find projects to contribute to')
      end
    end

    context 'when viewing public projects' do
      before do
        visit explore_projects_path
      end

      it_behaves_like 'explore page empty state'
    end

    context 'when viewing most starred projects' do
      before do
        visit starred_explore_projects_path
      end

      it_behaves_like 'explore page empty state'
    end

    context 'when viewing trending projects' do
      before do
        visit trending_explore_projects_path
      end

      it_behaves_like 'explore page empty state'
    end
  end

  def search(term)
    filter_input = find_by_testid('filtered-search-term-input')
    filter_input.click
    filter_input.set(term)
    click_button 'Search'
  end
end
