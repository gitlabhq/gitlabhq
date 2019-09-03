# frozen_string_literal: true

require 'spec_helper'

describe 'Dropdown assignee', :js do
  include FilteredSearchHelpers

  let!(:project) { create(:project) }
  let!(:user) { create(:user, name: 'administrator', username: 'root') }
  let!(:user_john) { create(:user, name: 'John', username: 'th0mas') }
  let!(:user_jacob) { create(:user, name: 'Jacob', username: 'otter32') }
  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_assignee) { '#js-dropdown-assignee' }
  let(:filter_dropdown) { find("#{js_dropdown_assignee} .filter-dropdown") }

  def dropdown_assignee_size
    filter_dropdown.all('.filter-dropdown-item').size
  end

  def click_assignee(text)
    find('#js-dropdown-assignee .filter-dropdown .filter-dropdown-item', text: text).click
  end

  before do
    project.add_maintainer(user)
    project.add_maintainer(user_john)
    project.add_maintainer(user_jacob)
    sign_in(user)
    create(:issue, project: project)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    it 'opens when the search bar has assignee:' do
      input_filtered_search('assignee:', submit: false, extra_space: false)

      expect(page).to have_css(js_dropdown_assignee, visible: true)
    end

    it 'closes when the search bar is unfocused' do
      find('body').click

      expect(page).to have_css(js_dropdown_assignee, visible: false)
    end

    it 'shows loading indicator when opened' do
      slow_requests do
        # We aren't using `input_filtered_search` because we want to see the loading indicator
        filtered_search.set('assignee:')

        expect(page).to have_css('#js-dropdown-assignee .filter-dropdown-loading', visible: true)
      end
    end

    it 'hides loading indicator when loaded' do
      input_filtered_search('assignee:', submit: false, extra_space: false)

      expect(find(js_dropdown_assignee)).not_to have_css('.filter-dropdown-loading')
    end

    it 'loads all the assignees when opened' do
      input_filtered_search('assignee:', submit: false, extra_space: false)

      expect(dropdown_assignee_size).to eq(4)
    end

    it 'shows current user at top of dropdown' do
      input_filtered_search('assignee:', submit: false, extra_space: false)

      expect(filter_dropdown.first('.filter-dropdown-item')).to have_content(user.name)
    end
  end

  describe 'filtering' do
    before do
      input_filtered_search('assignee:', submit: false, extra_space: false)

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_john.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user.name)
    end

    it 'filters by name' do
      input_filtered_search('jac', submit: false, extra_space: false)

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user.name)
    end

    it 'filters by case insensitive name' do
      input_filtered_search('JAC', submit: false, extra_space: false)

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user.name)
    end

    it 'filters by username with symbol' do
      input_filtered_search('@ott', submit: false, extra_space: false)

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user_john.name)
    end

    it 'filters by case insensitive username with symbol' do
      input_filtered_search('@OTT', submit: false, extra_space: false)

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user_john.name)
    end

    it 'filters by username without symbol' do
      input_filtered_search('ott', submit: false, extra_space: false)

      wait_for_requests

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user_john.name)
    end

    it 'filters by case insensitive username without symbol' do
      input_filtered_search('OTT', submit: false, extra_space: false)

      wait_for_requests

      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user_jacob.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_content(user.name)
      expect(find("#{js_dropdown_assignee} .filter-dropdown")).to have_no_content(user_john.name)
    end
  end

  describe 'selecting from dropdown' do
    before do
      input_filtered_search('assignee:', submit: false, extra_space: false)
    end

    it 'fills in the assignee username when the assignee has not been filtered' do
      click_assignee(user_jacob.name)

      wait_for_requests

      expect(page).to have_css(js_dropdown_assignee, visible: false)
      expect_tokens([assignee_token(user_jacob.name)])
      expect_filtered_search_input_empty
    end

    it 'fills in the assignee username when the assignee has been filtered' do
      input_filtered_search('roo', submit: false, extra_space: false)
      click_assignee(user.name)

      wait_for_requests

      expect(page).to have_css(js_dropdown_assignee, visible: false)
      expect_tokens([assignee_token(user.name)])
      expect_filtered_search_input_empty
    end

    it 'selects `None`' do
      find('#js-dropdown-assignee .filter-dropdown-item', text: 'None').click

      expect(page).to have_css(js_dropdown_assignee, visible: false)
      expect_tokens([assignee_token('None')])
      expect_filtered_search_input_empty
    end

    it 'selects `Any`' do
      find('#js-dropdown-assignee .filter-dropdown-item', text: 'Any').click

      expect(page).to have_css(js_dropdown_assignee, visible: false)
      expect_tokens([assignee_token('Any')])
      expect_filtered_search_input_empty
    end
  end

  describe 'selecting from dropdown without Ajax call' do
    before do
      Gitlab::Testing::RequestBlockerMiddleware.block_requests!
      input_filtered_search('assignee:', submit: false, extra_space: false)
    end

    after do
      Gitlab::Testing::RequestBlockerMiddleware.allow_requests!
    end

    it 'selects current user' do
      find('#js-dropdown-assignee .filter-dropdown-item', text: user.username).click

      expect(page).to have_css(js_dropdown_assignee, visible: false)
      expect_tokens([assignee_token(user.username)])
      expect_filtered_search_input_empty
    end
  end

  describe 'input has existing content' do
    it 'opens assignee dropdown with existing search term' do
      input_filtered_search('searchTerm assignee:', submit: false, extra_space: false)

      expect(page).to have_css(js_dropdown_assignee, visible: true)
    end

    it 'opens assignee dropdown with existing author' do
      input_filtered_search('author:@user assignee:', submit: false, extra_space: false)

      expect(page).to have_css(js_dropdown_assignee, visible: true)
    end

    it 'opens assignee dropdown with existing label' do
      input_filtered_search('label:~bug assignee:', submit: false, extra_space: false)

      expect(page).to have_css(js_dropdown_assignee, visible: true)
    end

    it 'opens assignee dropdown with existing milestone' do
      input_filtered_search('milestone:%v1.0 assignee:', submit: false, extra_space: false)

      expect(page).to have_css(js_dropdown_assignee, visible: true)
    end

    it 'opens assignee dropdown with existing my-reaction' do
      input_filtered_search('my-reaction:star assignee:', submit: false, extra_space: false)

      expect(page).to have_css(js_dropdown_assignee, visible: true)
    end
  end

  describe 'caching requests' do
    it 'caches requests after the first load' do
      input_filtered_search('assignee:', submit: false, extra_space: false)
      initial_size = dropdown_assignee_size

      expect(initial_size).to be > 0

      new_user = create(:user)
      project.add_maintainer(new_user)
      find('.filtered-search-box .clear-search').click
      input_filtered_search('assignee:', submit: false, extra_space: false)

      expect(dropdown_assignee_size).to eq(initial_size)
    end
  end
end
