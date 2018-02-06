require 'rails_helper'

describe 'Dropdown author', :js do
  include FilteredSearchHelpers

  let!(:project) { create(:project) }
  let!(:user) { create(:user, name: 'administrator', username: 'root') }
  let!(:user_john) { create(:user, name: 'John', username: 'th0mas') }
  let!(:user_jacob) { create(:user, name: 'Jacob', username: 'ooter32') }
  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_author) { '#js-dropdown-author' }

  def send_keys_to_filtered_search(input)
    input.split("").each do |i|
      filtered_search.send_keys(i)
    end

    sleep 0.5
    wait_for_requests
  end

  def dropdown_author_size
    page.all('#js-dropdown-author .filter-dropdown .filter-dropdown-item').size
  end

  def click_author(text)
    find('#js-dropdown-author .filter-dropdown .filter-dropdown-item', text: text).click
  end

  before do
    project.add_master(user)
    project.add_master(user_john)
    project.add_master(user_jacob)
    sign_in(user)
    create(:issue, project: project)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    it 'opens when the search bar has author:' do
      filtered_search.set('author:')

      expect(page).to have_css(js_dropdown_author, visible: true)
    end

    it 'closes when the search bar is unfocused' do
      find('body').click()

      expect(page).to have_css(js_dropdown_author, visible: false)
    end

    it 'should show loading indicator when opened' do
      slow_requests do
        filtered_search.set('author:')

        expect(page).to have_css('#js-dropdown-author .filter-dropdown-loading', visible: true)
      end
    end

    it 'should hide loading indicator when loaded' do
      send_keys_to_filtered_search('author:')

      expect(page).not_to have_css('#js-dropdown-author .filter-dropdown-loading')
    end

    it 'should load all the authors when opened' do
      send_keys_to_filtered_search('author:')

      expect(dropdown_author_size).to eq(4)
    end

    it 'shows current user at top of dropdown' do
      send_keys_to_filtered_search('author:')

      expect(first('#js-dropdown-author li')).to have_content(user.name)
    end
  end

  describe 'filtering' do
    before do
      filtered_search.set('author')
      send_keys_to_filtered_search(':')
    end

    it 'filters by name' do
      send_keys_to_filtered_search('jac')

      expect(dropdown_author_size).to eq(1)
    end

    it 'filters by case insensitive name' do
      send_keys_to_filtered_search('Jac')

      expect(dropdown_author_size).to eq(1)
    end

    it 'filters by username with symbol' do
      send_keys_to_filtered_search('@oot')

      expect(dropdown_author_size).to eq(2)
    end

    it 'filters by username without symbol' do
      send_keys_to_filtered_search('oot')

      expect(dropdown_author_size).to eq(2)
    end

    it 'filters by case insensitive username without symbol' do
      send_keys_to_filtered_search('OOT')

      expect(dropdown_author_size).to eq(2)
    end
  end

  describe 'selecting from dropdown' do
    before do
      filtered_search.set('author')
      send_keys_to_filtered_search(':')
    end

    it 'fills in the author username when the author has not been filtered' do
      click_author(user_jacob.name)

      wait_for_requests

      expect(page).to have_css(js_dropdown_author, visible: false)
      expect_tokens([author_token(user_jacob.name)])
      expect_filtered_search_input_empty
    end

    it 'fills in the author username when the author has been filtered' do
      click_author(user.name)

      wait_for_requests

      expect(page).to have_css(js_dropdown_author, visible: false)
      expect_tokens([author_token(user.name)])
      expect_filtered_search_input_empty
    end
  end

  describe 'selecting from dropdown without Ajax call' do
    before do
      Gitlab::Testing::RequestBlockerMiddleware.block_requests!
      filtered_search.set('author:')
    end

    after do
      Gitlab::Testing::RequestBlockerMiddleware.allow_requests!
    end

    it 'selects current user' do
      find('#js-dropdown-author .filter-dropdown-item', text: user.username).click

      expect(page).to have_css(js_dropdown_author, visible: false)
      expect_tokens([author_token(user.username)])
      expect_filtered_search_input_empty
    end
  end

  describe 'input has existing content' do
    it 'opens author dropdown with existing search term' do
      filtered_search.set('searchTerm author:')

      expect(page).to have_css(js_dropdown_author, visible: true)
    end

    it 'opens author dropdown with existing assignee' do
      filtered_search.set('assignee:@user author:')

      expect(page).to have_css(js_dropdown_author, visible: true)
    end

    it 'opens author dropdown with existing label' do
      filtered_search.set('label:~bug author:')

      expect(page).to have_css(js_dropdown_author, visible: true)
    end

    it 'opens author dropdown with existing milestone' do
      filtered_search.set('milestone:%v1.0 author:')

      expect(page).to have_css(js_dropdown_author, visible: true)
    end
  end

  describe 'caching requests' do
    it 'caches requests after the first load' do
      filtered_search.set('author')
      send_keys_to_filtered_search(':')
      initial_size = dropdown_author_size

      expect(initial_size).to be > 0

      new_user = create(:user)
      project.add_master(new_user)
      find('.filtered-search-box .clear-search').click
      filtered_search.set('author')
      send_keys_to_filtered_search(':')

      expect(dropdown_author_size).to eq(initial_size)
    end
  end
end
