# frozen_string_literal: true

require 'spec_helper'

describe 'Search bar', :js do
  include FilteredSearchHelpers

  let!(:project) { create(:project) }
  let!(:user) { create(:user) }
  let(:filtered_search) { find('.filtered-search') }

  before do
    project.add_maintainer(user)
    sign_in(user)
    create(:issue, project: project)

    visit project_issues_path(project)
  end

  def get_left_style(style)
    left_style = /left:\s\d*[.]\d*px/.match(style)
    left_style.to_s.gsub('left: ', '').to_f
  end

  describe 'keyboard navigation' do
    it 'makes item active' do
      filtered_search.native.send_keys(:down)

      page.within '#js-dropdown-hint' do
        expect(page).to have_selector('.droplab-item-active')
      end
    end

    it 'selects item' do
      filtered_search.native.send_keys(:down, :down, :enter)

      expect_tokens([{ name: 'Assignee' }])
      expect_filtered_search_input_empty
    end
  end

  describe 'clear search button' do
    it 'clears text' do
      search_text = 'search_text'
      filtered_search.set(search_text)

      expect(filtered_search.value).to eq(search_text)
      find('.filtered-search-box .clear-search').click

      expect(filtered_search.value).to eq('')
    end

    it 'hides by default' do
      expect(page).to have_css('.clear-search', visible: false)
    end

    it 'hides after clicked' do
      filtered_search.set('a')
      find('.filtered-search-box .clear-search').click

      expect(page).to have_css('.clear-search', visible: false)
    end

    it 'hides when there is no text' do
      filtered_search.set('a')
      filtered_search.set('')

      expect(page).to have_css('.clear-search', visible: false)
    end

    it 'shows when there is text' do
      filtered_search.set('a')

      expect(page).to have_css('.clear-search', visible: true)
    end

    it 'resets the dropdown hint filter' do
      filtered_search.click
      original_size = page.all('#js-dropdown-hint .filter-dropdown .filter-dropdown-item').size

      filtered_search.set('autho')

      expect(find('#js-dropdown-hint')).to have_selector('.filter-dropdown .filter-dropdown-item', count: 1)

      find('.filtered-search-box .clear-search').click
      filtered_search.click

      expect(find('#js-dropdown-hint')).to have_selector('.filter-dropdown .filter-dropdown-item', count: original_size)
    end

    it 'resets the dropdown filters', :quarantine do
      filtered_search.click

      hint_offset = get_left_style(find('#js-dropdown-hint')['style'])

      filtered_search.set('a')

      filtered_search.set('author:')

      find('#js-dropdown-hint', visible: false)

      find('.filtered-search-box .clear-search').click
      filtered_search.click

      expect(find('#js-dropdown-hint')).to have_selector('.filter-dropdown .filter-dropdown-item', count: 6)
      expect(get_left_style(find('#js-dropdown-hint')['style'])).to eq(hint_offset)
    end
  end
end
