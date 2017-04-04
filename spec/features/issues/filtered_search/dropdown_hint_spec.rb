require 'rails_helper'

describe 'Dropdown hint', js: true, feature: true do
  include FilteredSearchHelpers
  include WaitForAjax

  let!(:project) { create(:empty_project) }
  let!(:user) { create(:user) }
  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_hint) { '#js-dropdown-hint' }

  def dropdown_hint_size
    page.all('#js-dropdown-hint .filter-dropdown .filter-dropdown-item').size
  end

  def click_hint(text)
    find('#js-dropdown-hint .filter-dropdown .filter-dropdown-item', text: text).click
  end

  before do
    project.team << [user, :master]
    login_as(user)
    create(:issue, project: project)

    visit namespace_project_issues_path(project.namespace, project)
  end

  describe 'behavior' do
    before do
      expect(page).to have_css(js_dropdown_hint, visible: false)
      filtered_search.click
    end

    it 'opens when the search bar is first focused' do
      expect(page).to have_css(js_dropdown_hint, visible: true)
    end

    it 'closes when the search bar is unfocused' do
      find('body').click

      expect(page).to have_css(js_dropdown_hint, visible: false)
    end
  end

  describe 'filtering' do
    it 'does not filter `Press Enter or click to search`' do
      filtered_search.set('randomtext')

      expect(page).to have_css(js_dropdown_hint, text: 'Press Enter or click to search', visible: false)
      expect(dropdown_hint_size).to eq(0)
    end

    it 'filters with text' do
      filtered_search.set('a')

      expect(dropdown_hint_size).to eq(3)
    end
  end

  describe 'selecting from dropdown with no input' do
    before do
      filtered_search.click
    end

    it 'opens the author dropdown when you click on author' do
      click_hint('author')

      expect(page).to have_css(js_dropdown_hint, visible: false)
      expect(page).to have_css('#js-dropdown-author', visible: true)
      expect_tokens([{ name: 'author' }])
      expect_filtered_search_input_empty
    end

    it 'opens the assignee dropdown when you click on assignee' do
      click_hint('assignee')

      expect(page).to have_css(js_dropdown_hint, visible: false)
      expect(page).to have_css('#js-dropdown-assignee', visible: true)
      expect_tokens([{ name: 'assignee' }])
      expect_filtered_search_input_empty
    end

    it 'opens the milestone dropdown when you click on milestone' do
      click_hint('milestone')

      expect(page).to have_css(js_dropdown_hint, visible: false)
      expect(page).to have_css('#js-dropdown-milestone', visible: true)
      expect_tokens([{ name: 'milestone' }])
      expect_filtered_search_input_empty
    end

    it 'opens the label dropdown when you click on label' do
      click_hint('label')

      expect(page).to have_css(js_dropdown_hint, visible: false)
      expect(page).to have_css('#js-dropdown-label', visible: true)
      expect_tokens([{ name: 'label' }])
      expect_filtered_search_input_empty
    end
  end

  describe 'selecting from dropdown with some input' do
    it 'opens the author dropdown when you click on author' do
      filtered_search.set('auth')
      click_hint('author')

      expect(page).to have_css(js_dropdown_hint, visible: false)
      expect(page).to have_css('#js-dropdown-author', visible: true)
      expect_tokens([{ name: 'author' }])
      expect_filtered_search_input_empty
    end

    it 'opens the assignee dropdown when you click on assignee' do
      filtered_search.set('assign')
      click_hint('assignee')

      expect(page).to have_css(js_dropdown_hint, visible: false)
      expect(page).to have_css('#js-dropdown-assignee', visible: true)
      expect_tokens([{ name: 'assignee' }])
      expect_filtered_search_input_empty
    end

    it 'opens the milestone dropdown when you click on milestone' do
      filtered_search.set('mile')
      click_hint('milestone')

      expect(page).to have_css(js_dropdown_hint, visible: false)
      expect(page).to have_css('#js-dropdown-milestone', visible: true)
      expect_tokens([{ name: 'milestone' }])
      expect_filtered_search_input_empty
    end

    it 'opens the label dropdown when you click on label' do
      filtered_search.set('lab')
      click_hint('label')

      expect(page).to have_css(js_dropdown_hint, visible: false)
      expect(page).to have_css('#js-dropdown-label', visible: true)
      expect_tokens([{ name: 'label' }])
      expect_filtered_search_input_empty
    end
  end

  describe 'reselecting from dropdown' do
    it 'reuses existing author text' do
      filtered_search.send_keys('author:')
      filtered_search.send_keys(:backspace)
      click_hint('author')

      expect_tokens([{ name: 'author' }])
      expect_filtered_search_input_empty
    end

    it 'reuses existing assignee text' do
      filtered_search.send_keys('assignee:')
      filtered_search.send_keys(:backspace)
      click_hint('assignee')

      expect_tokens([{ name: 'assignee' }])
      expect_filtered_search_input_empty
    end

    it 'reuses existing milestone text' do
      filtered_search.send_keys('milestone:')
      filtered_search.send_keys(:backspace)
      click_hint('milestone')

      expect_tokens([{ name: 'milestone' }])
      expect_filtered_search_input_empty
    end

    it 'reuses existing label text' do
      filtered_search.send_keys('label:')
      filtered_search.send_keys(:backspace)
      click_hint('label')

      expect_tokens([{ name: 'label' }])
      expect_filtered_search_input_empty
    end
  end
end
