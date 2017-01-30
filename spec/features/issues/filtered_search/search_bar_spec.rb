require 'rails_helper'

describe 'Search bar', js: true, feature: true do
  include WaitForAjax

  let!(:project) { create(:empty_project) }
  let!(:user) { create(:user) }
  let(:filtered_search) { find('.filtered-search') }

  before do
    project.team << [user, :master]
    login_as(user)
    create(:issue, project: project)

    visit namespace_project_issues_path(project.namespace, project)
  end

  def get_left_style(style)
    left_style = /left:\s\d*[.]\d*px/.match(style)
    left_style.to_s.gsub('left: ', '').to_f
  end

  describe 'keyboard navigation' do
    it 'makes item active' do
      filtered_search.native.send_keys(:down)

      page.within '#js-dropdown-hint' do
        expect(page).to have_selector('.dropdown-active')
      end
    end

    it 'selects item' do
      filtered_search.native.send_keys(:down, :down, :enter)

      expect(filtered_search.value).to eq('author:')
    end
  end

  describe 'clear search button' do
    it 'clears text' do
      search_text = 'search_text'
      filtered_search.set(search_text)

      expect(filtered_search.value).to eq(search_text)
      find('.filtered-search-input-container .clear-search').click

      expect(filtered_search.value).to eq('')
    end

    it 'hides by default' do
      expect(page).to have_css('.clear-search', visible: false)
    end

    it 'hides after clicked' do
      filtered_search.set('a')
      find('.filtered-search-input-container .clear-search').click

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

      filtered_search.set('author')

      expect(page.all('#js-dropdown-hint .filter-dropdown .filter-dropdown-item').size).to eq(1)

      find('.filtered-search-input-container .clear-search').click
      filtered_search.click

      expect(page.all('#js-dropdown-hint .filter-dropdown .filter-dropdown-item').size).to eq(original_size)
    end

    it 'resets the dropdown filters' do
      filtered_search.set('a')
      hint_style = page.find('#js-dropdown-hint')['style']
      hint_offset = get_left_style(hint_style)

      filtered_search.set('author:')

      expect(page.all('#js-dropdown-hint .filter-dropdown .filter-dropdown-item').size).to eq(0)

      find('.filtered-search-input-container .clear-search').click
      filtered_search.click

      expect(page.all('#js-dropdown-hint .filter-dropdown .filter-dropdown-item').size).to be > 0
      expect(get_left_style(page.find('#js-dropdown-hint')['style'])).to eq(hint_offset)
    end
  end
end
