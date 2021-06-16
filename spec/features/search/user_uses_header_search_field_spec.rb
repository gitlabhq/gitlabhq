# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User uses header search field', :js do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }

  let(:user) { reporter }

  before_all do
    project.add_reporter(reporter)
    project.add_developer(developer)
  end

  before do
    sign_in(user)
  end

  shared_examples 'search field examples' do
    before do
      visit(url)
    end

    it 'starts searching by pressing the enter key' do
      submit_search('gitlab')

      page.within('.page-title') do
        expect(page).to have_content('Search')
      end
    end

    context 'when using the keyboard shortcut' do
      before do
        find('#search')
        find('body').native.send_keys('s')

        wait_for_all_requests
      end

      it 'shows the category search dropdown', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/250285' do
        expect(page).to have_selector('.dropdown-header', text: /#{scope_name}/i)
      end
    end

    context 'when clicking the search field' do
      before do
        page.find('#search').click
      end

      it 'shows category search dropdown', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/250285' do
        expect(page).to have_selector('.dropdown-header', text: /#{scope_name}/i)
      end

      context 'when clicking issues', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/332317' do
        let!(:issue) { create(:issue, project: project, author: user, assignees: [user]) }

        it 'shows assigned issues' do
          find('.search-input-container .dropdown-menu').click_link('Issues assigned to me')

          expect(page).to have_selector('.issues-list .issue')
          expect_tokens([assignee_token(user.name)])
          expect_filtered_search_input_empty
        end

        it 'shows created issues' do
          find('.search-input-container .dropdown-menu').click_link("Issues I've created")

          expect(page).to have_selector('.issues-list .issue')
          expect_tokens([author_token(user.name)])
          expect_filtered_search_input_empty
        end
      end

      context 'when clicking merge requests', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/332317' do
        let!(:merge_request) { create(:merge_request, source_project: project, author: user, assignees: [user]) }

        it 'shows assigned merge requests' do
          find('.search-input-container .dropdown-menu').click_link('Merge requests assigned to me')

          expect(page).to have_selector('.mr-list .merge-request')
          expect_tokens([assignee_token(user.name)])
          expect_filtered_search_input_empty
        end

        it 'shows created merge requests' do
          find('.search-input-container .dropdown-menu').click_link("Merge requests I've created")

          expect(page).to have_selector('.mr-list .merge-request')
          expect_tokens([author_token(user.name)])
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
      let(:scope_name) { 'All GitLab' }
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
        expect(page).to have_content('Projects 1')
        expect(page).to have_content('Issues 1')
        expect(page).to have_content('Merge requests 0')
        expect(page).to have_content('Milestones 0')
        expect(page).to have_content('Users 0')
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

        expect(page).to have_selector(scoped_search_link('test'))
        expect(page).to have_selector(scoped_search_link('test', group_id: group.id))
        expect(page).to have_selector(scoped_search_link('test', project_id: project.id, group_id: group.id))
      end
    end

    context 'and it belongs to a user' do
      include_examples 'search field examples' do
        let(:url) { project_path(project) }
        let(:scope_name) { project.name }
      end

      it 'displays search options' do
        fill_in_search('test')

        expect(page).to have_selector(scoped_search_link('test'))
        expect(page).not_to have_selector(scoped_search_link('test', group_id: project.namespace_id))
        expect(page).to have_selector(scoped_search_link('test', project_id: project.id))
      end

      it 'displays a link to project merge requests' do
        fill_in_search('Merge')

        within(dashboard_search_options_popup_menu) do
          expect(page).to have_text('Merge requests')
        end
      end

      it 'does not display a link to project feature flags' do
        fill_in_search('Feature')

        within(dashboard_search_options_popup_menu) do
          expect(page).to have_text('"Feature" in all GitLab')
          expect(page).to have_no_text('Feature Flags')
        end
      end

      context 'and user is a developer' do
        let(:user) { developer }

        it 'displays a link to project feature flags' do
          fill_in_search('Feature')

          within(dashboard_search_options_popup_menu) do
            expect(page).to have_text('Feature Flags')
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
      expect(page).to have_selector(scoped_search_link('test', group_id: group.id))
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
      expect(page).to have_selector(scoped_search_link('test', group_id: subgroup.id))
      expect(page).not_to have_selector(scoped_search_link('test', project_id: project.id))
    end
  end

  def scoped_search_link(term, project_id: nil, group_id: nil)
    # search_path will accept group_id and project_id but the order does not match
    # what is expected in the href, so the variable must be built manually
    href = search_path(search: term)
    href.concat("&project_id=#{project_id}") if project_id
    href.concat("&group_id=#{group_id}") if group_id

    ".dropdown a[href='#{href}']"
  end

  def dashboard_search_options_popup_menu
    "div[data-testid='dashboard-search-options']"
  end
end
