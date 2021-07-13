# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dropdown hint', :js do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_hint) { '#js-dropdown-hint' }
  let(:js_dropdown_operator) { '#js-dropdown-operator' }

  def click_hint(text)
    find('#js-dropdown-hint .filter-dropdown .filter-dropdown-item', text: text).click
  end

  def click_operator(op)
    find("#js-dropdown-operator .filter-dropdown .filter-dropdown-item[data-value='#{op}']").click
  end

  before do
    project.add_maintainer(user)
  end

  context 'when user not logged in' do
    before do
      visit project_issues_path(project)
    end

    it 'does not exist my-reaction dropdown item' do
      expect(page).to have_css(js_dropdown_hint, visible: false)
      expect(page).not_to have_content('My-reaction')
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
        click_hint('Author')

        expect(page).to have_css(js_dropdown_hint, visible: false)
        expect(page).to have_css(js_dropdown_operator, visible: true)

        click_operator('=')

        expect(page).to have_css(js_dropdown_hint, visible: false)
        expect(page).to have_css(js_dropdown_operator, visible: false)
        expect(page).to have_css('#js-dropdown-author', visible: true)
        expect_tokens([{ name: 'Author', operator: '=' }])
        expect_filtered_search_input_empty
      end
    end

    describe 'reselecting from dropdown' do
      it 'reuses existing token text' do
        filtered_search.send_keys('author')
        filtered_search.send_keys(:backspace)
        filtered_search.send_keys(:backspace)
        click_hint('Author')

        expect_tokens([{ name: 'Author' }])
        expect_filtered_search_input_empty
      end
    end
  end
end
