# frozen_string_literal: true

require 'spec_helper'

describe 'User uses header search field', :js do
  include FilteredSearchHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_reporter(user)
    sign_in(user)
  end

  shared_examples 'search field examples' do
    before do
      visit(url)
    end

    it 'starts searching by pressing the enter key' do
      fill_in('search', with: 'gitlab')
      find('#search').native.send_keys(:enter)

      page.within('.page-title') do
        expect(page).to have_content('Search')
      end
    end

    context 'when clicking the search field' do
      before do
        page.find('#search').click
        wait_for_all_requests
      end

      it 'shows category search dropdown' do
        expect(page).to have_selector('.dropdown-header', text: /#{scope_name}/i)
      end

      context 'when clicking issues' do
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

      context 'when clicking merge requests' do
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
      before do
        page.within('.search-input-wrap') do
          fill_in('search', with: scope_name.first(4))
        end
      end

      it 'does not display the category search dropdown' do
        expect(page).not_to have_selector('.dropdown-header', text: /#{scope_name}/i)
      end
    end
  end

  context 'when user is in a global scope' do
    include_examples 'search field examples' do
      let(:url) { root_path }
      let(:scope_name) { 'All GitLab' }
    end
  end

  context 'when user is in a project scope' do
    include_examples 'search field examples' do
      let(:url) { project_path(project) }
      let(:scope_name) { project.name }
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
  end
end
