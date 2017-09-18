require 'spec_helper'

describe 'User uses header search field' do
  include FilteredSearchHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_reporter(user)
    sign_in(user)

    visit(project_path(project))
  end

  it 'starts searching by pressing the enter key', :js do
    fill_in('search', with: 'gitlab')
    find('#search').native.send_keys(:enter)

    page.within('.breadcrumbs-sub-title') do
      expect(page).to have_content('Search')
    end
  end

  it 'contains location badge' do
    expect(page).to have_selector('.has-location-badge')
  end

  context 'when clicking the search field', :js do
    before do
      page.find('#search').click
    end

    it 'shows category search dropdown' do
      expect(page).to have_selector('.dropdown-header', text: /#{project.name}/i)
    end

    context 'when clicking issues' do
      let!(:issue) { create(:issue, project: project, author: user, assignees: [user]) }

      it 'shows assigned issues' do
        find('.dropdown-menu').click_link('Issues assigned to me')

        expect(page).to have_selector('.filtered-search')
        expect_tokens([assignee_token(user.name)])
        expect_filtered_search_input_empty
      end

      it 'shows created issues' do
        find('.dropdown-menu').click_link("Issues I've created")

        expect(page).to have_selector('.filtered-search')
        expect_tokens([author_token(user.name)])
        expect_filtered_search_input_empty
      end
    end

    context 'when clicking merge requests' do
      let!(:merge_request) { create(:merge_request, source_project: project, author: user, assignee: user) }

      it 'shows assigned merge requests' do
        find('.dropdown-menu').click_link('Merge requests assigned to me')

        expect(page).to have_selector('.merge-requests-holder')
        expect_tokens([assignee_token(user.name)])
        expect_filtered_search_input_empty
      end

      it 'shows created merge requests' do
        find('.dropdown-menu').click_link("Merge requests I've created")

        expect(page).to have_selector('.merge-requests-holder')
        expect_tokens([author_token(user.name)])
        expect_filtered_search_input_empty
      end
    end
  end

  context 'when entering text into the search field', :js do
    before do
      page.within('.search-input-wrap') do
        fill_in('search', with: project.name[0..3])
      end
    end

    it 'does not display the category search dropdown' do
      expect(page).not_to have_selector('.dropdown-header', text: /#{project.name}/i)
    end
  end
end
