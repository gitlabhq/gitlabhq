# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User uses header search field', :js, :disable_rate_limiter, feature_category: :global_search do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  let(:user) { reporter }

  before do
    sign_in(user)
  end

  shared_examples 'search field examples' do
    before do
      visit(url)
      wait_for_all_requests
    end

    context 'when searching by pressing the enter key' do
      before do
        submit_search('gitlab')
      end

      it 'renders breadcrumbs' do
        within_testid('breadcrumb-links') do
          expect(page).to have_content('Search')
        end
      end
    end

    context 'when using the keyboard shortcut' do
      before do
        find('body').native.send_keys('s')
      end

      it 'shows the search modal' do
        expect(page).to have_selector(search_modal_results, visible: :visible)
      end
    end

    context 'when clicking the search button' do
      before do
        click_button "Search or go to…"
        wait_for_all_requests
      end

      it 'shows search scopes list' do
        fill_in 'search', with: 'text'
        within('#super-sidebar-search-modal') do
          expect(page).to have_selector('[data-testid="scoped-items"]', text: scope_name)
        end
      end

      context 'when clicking issues' do
        let!(:issue) { create(:issue, project: project, author: user, assignees: [user]) }

        it 'shows assigned issues' do
          find(search_modal_results).click_link('Issues assigned to me')

          expect(page).to have_selector('.issues-list .issue')
          expect_assignee_token(user.name)
          expect_filtered_search_input_empty
        end

        it 'shows created issues' do
          find(search_modal_results).click_link("Issues I've created")

          expect(page).to have_selector('.issues-list .issue')
          expect_author_token(user.name)
          expect_filtered_search_input_empty
        end
      end

      context 'when clicking merge requests' do
        let!(:merge_request) { create(:merge_request, source_project: project, author: user, assignees: [user]) }

        it 'shows assigned merge requests' do
          find(search_modal_results).click_link('Merge requests assigned to me')

          expect(page).to have_selector('.issuable-list .merge-request')
          expect_assignee_token(user.name)
          expect_filtered_search_input_empty
        end

        it 'shows created merge requests' do
          find(search_modal_results).click_link("Merge requests I've created")

          expect(page).to have_selector('.issuable-list .merge-request')
          expect_author_token(user.name)
          expect_filtered_search_input_empty
        end
      end
    end

    context 'when entering text into the search field' do
      it 'does not display the category search dropdown' do
        fill_in_search(scope_name.first(4))

        expect(page).not_to have_selector('.dropdown-header', text: /#{scope_name}/i)
      end
    end
  end

  context 'when user is in a global scope' do
    include_examples 'search field examples' do
      let(:url) { root_path }
      let(:scope_name) { 'all GitLab' }
    end

    it 'displays search options', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/251076' do
      fill_in_search('test')

      expect(page).to have_selector(scoped_search_link('test'))
    end

    context 'when searching through the search field' do
      before do
        create(:issue, project: project, title: 'project issue')

        submit_search('project')
      end

      it 'displays result counts for all categories' do
        within_testid('super-sidebar') do
          expect(page).to have_link('Projects 1')
          expect(page).to have_link('issue')
          expect(page).to have_link('Merge requests 0')
          expect(page).to have_link('Milestones 0')
          expect(page).to have_link('Users 0')
        end
      end
    end
  end

  context 'when user is in a project scope' do
    context 'and it belongs to a group' do
      let(:group) { create(:group) }
      let(:project) { create(:project, namespace: group) }

      before do
        project.add_reporter(user)
      end

      include_examples 'search field examples' do
        let(:url) { project_path(project) }
        let(:scope_name) { project.name }
      end

      it 'displays search options' do
        fill_in_search('test')

        expect(page).to have_selector(scoped_search_link('test', group_id: group.id, search_code: true))
        expect(page).to have_selector(scoped_search_link('test', search_code: true))
      end
    end

    context 'and it belongs to a user' do
      include_examples 'search field examples' do
        let(:url) { project_path(project) }
        let(:scope_name) { project.name }
      end

      it 'displays search options' do
        fill_in_search('test')

        expect(page).not_to have_selector(scoped_search_link('test', search_code: true, group_id: project.namespace_id, repository_ref: 'master'))
        expect(page).to have_selector(scoped_search_link('test', search_code: true, repository_ref: 'master'))
      end

      it 'displays a link to project merge requests' do
        fill_in_search('Merge')

        within(search_modal_results) do
          expect(page).to have_link('Merge requests')
        end
      end

      it 'does not display a link to project feature flags' do
        fill_in_search('Feature')

        within_testid("scoped-items") do
          expect(page).to have_content('Search for `Feature` in...')
          expect(page).to have_link('all GitLab')
          expect(page).not_to have_link('Feature Flags')
        end
      end

      context 'and user is a developer' do
        let(:user) { developer }

        it 'displays a link to project feature flags' do
          fill_in_search('Feature')

          within(search_modal_results) do
            expect(page).to have_link('Feature Flags')
          end
        end
      end
    end
  end

  context 'when user is in a group scope' do
    let(:group) { create(:group) }
    let(:project) { create(:project, namespace: group) }

    before do
      group.add_maintainer(user)
    end

    include_examples 'search field examples' do
      let(:url) { group_path(group) }
      let(:scope_name) { group.name }
    end

    it 'displays search options' do
      fill_in_search('test')

      expect(page).to have_selector(scoped_search_link('test'))
      expect(page).not_to have_selector(scoped_search_link('test', project_id: project.id))
    end
  end

  context 'when user is in a subgroup scope' do
    let(:group) { create(:group) }
    let(:subgroup) { create(:group, :public, parent: group) }
    let(:project) { create(:project, namespace: subgroup) }

    before do
      group.add_owner(user)
      subgroup.add_owner(user)
    end

    include_examples 'search field examples' do
      let(:url) { group_path(subgroup) }
      let(:scope_name) { subgroup.name }
    end

    it 'displays search options' do
      fill_in_search('test')

      expect(page).to have_selector(scoped_search_link('test'))
      expect(page).not_to have_selector(scoped_search_link('test', project_id: project.id))
    end
  end

  def scoped_search_link(term, project_id: nil, group_id: nil, search_code: nil, repository_ref: nil)
    # search_path will accept group_id and project_id but the order does not match
    # what is expected in the href, so the variable must be built manually
    href = search_path(search: term)
    href.concat("&nav_source=navbar")
    href.concat("&project_id=#{project_id}") if project_id
    href.concat("&group_id=#{group_id}") if group_id
    href.concat("&search_code=true") if search_code
    href.concat("&repository_ref=#{repository_ref}") if repository_ref

    ".global-search-results a[href='#{href}']"
  end

  def search_modal_results
    ".global-search-results"
  end
end
