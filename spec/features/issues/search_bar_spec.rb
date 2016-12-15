require 'rails_helper'

describe 'Search bar', js: true, feature: true do
  include WaitForAjax

  let!(:project) { create(:empty_project) }
  let!(:user) { create(:user) }

  before do
    project.team << [user, :master]
    login_as(user)
    create(:issue, project: project)

    visit namespace_project_issues_path(project.namespace, project)
  end

  describe 'clear search button' do
    it 'clears text' do
      search_text = 'search_text'
      filtered_search = find('.filtered-search')
      filtered_search.set(search_text)

      expect(filtered_search.value).to eq(search_text)
      find('.filtered-search-input-container .clear-search').click
      expect(filtered_search.value).to eq('')
    end

    it 'hides by default' do
      expect(page).to have_css('.clear-search', visible: false)
    end

    it 'hides after clicked' do
      filtered_search = find('.filtered-search')
      filtered_search.set('a')
      find('.filtered-search-input-container .clear-search').click
      expect(page).to have_css('.clear-search', visible: false)
    end

    it 'hides when there is no text' do
      filtered_search = find('.filtered-search')
      filtered_search.set('a')
      filtered_search.set('')
      expect(page).to have_css('.clear-search', visible: false)
    end

    it 'shows when there is text' do
      filtered_search = find('.filtered-search')
      filtered_search.set('a')

      expect(page).to have_css('.clear-search', visible: true)
    end
  end
end
