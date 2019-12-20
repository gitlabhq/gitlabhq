# frozen_string_literal: true

require 'spec_helper'

describe 'Dropdown hint', :js do
  include FilteredSearchHelpers

  let!(:project) { create(:project, :public) }
  let!(:user) { create(:user) }
  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_hint) { '#js-dropdown-hint' }

  def click_hint(text)
    find('#js-dropdown-hint .filter-dropdown .filter-dropdown-item', text: text).click
  end

  before do
    project.add_maintainer(user)
    create(:issue, project: project)
    create(:merge_request, source_project: project, target_project: project)
  end

  context 'when user not logged in' do
    before do
      visit project_issues_path(project)
    end

    it 'does not exist my-reaction dropdown item' do
      expect(page).to have_css(js_dropdown_hint, visible: false)
      expect(page).not_to have_content('my-reaction')
    end
  end

  context 'when user logged in' do
    before do
      sign_in(user)

      visit project_issues_path(project)
    end

    describe 'behavior' do
      before do
        expect(page).to have_css(js_dropdown_hint, visible: false)
        filtered_search.click
      end

      it 'opens when the search bar is first focused' do
        expect(page).to have_css(js_dropdown_hint, visible: true)

        find('body').click

        expect(page).to have_css(js_dropdown_hint, visible: false)
      end
    end

    describe 'filtering' do
      it 'does not filter `Press Enter or click to search`' do
        filtered_search.set('randomtext')

        hint_dropdown = find(js_dropdown_hint)

        expect(hint_dropdown).to have_content('Press Enter or click to search')
        expect(hint_dropdown).to have_selector('.filter-dropdown .filter-dropdown-item', count: 0)
      end

      it 'filters with text' do
        filtered_search.set('a')

        expect(find(js_dropdown_hint)).to have_selector('.filter-dropdown .filter-dropdown-item', count: 6)
      end
    end

    describe 'selecting from dropdown with no input' do
      before do
        filtered_search.click
      end

      it 'opens the token dropdown when you click on it' do
        click_hint('author')

        expect(page).to have_css(js_dropdown_hint, visible: false)
        expect(page).to have_css('#js-dropdown-author', visible: true)
        expect_tokens([{ name: 'Author' }])
        expect_filtered_search_input_empty
      end
    end

    describe 'reselecting from dropdown' do
      it 'reuses existing token text' do
        filtered_search.send_keys('author:')
        filtered_search.send_keys(:backspace)
        filtered_search.send_keys(:backspace)
        click_hint('author')

        expect_tokens([{ name: 'Author' }])
        expect_filtered_search_input_empty
      end
    end
  end
end
