# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Recent searches', :js do
  include FilteredSearchHelpers
  include MobileHelpers

  let_it_be(:project_1) { create(:project, :public) }
  let_it_be(:project_2) { create(:project, :public) }
  let_it_be(:issue_1) { create(:issue, project: project_1) }
  let_it_be(:issue_2) { create(:issue, project: project_2) }

  let(:project_1_local_storage_key) { "#{project_1.full_path}-issue-recent-searches" }

  before do
    Capybara.ignore_hidden_elements = false

    # Visit any fast-loading page so we can clear local storage without a DOM exception
    visit '/404'
    remove_recent_searches
  end

  after do
    Capybara.ignore_hidden_elements = true
  end

  it 'searching adds to recent searches' do
    visit project_issues_path(project_1)

    input_filtered_search('foo', submit: true)
    input_filtered_search('bar', submit: true)

    items = all('.filtered-search-history-dropdown-item', visible: false, count: 2)

    expect(items[0].text).to eq('bar')
    expect(items[1].text).to eq('foo')
  end

  it 'visiting URL with search params adds to recent searches' do
    visit project_issues_path(project_1, label_name: 'foo', search: 'bar')
    visit project_issues_path(project_1, label_name: 'qux', search: 'garply')

    items = all('.filtered-search-history-dropdown-item', visible: false, count: 2)

    expect(items[0].text).to eq('label: = ~qux garply')
    expect(items[1].text).to eq('label: = ~foo bar')
  end

  it 'saved recent searches are restored last on the list' do
    set_recent_searches(project_1_local_storage_key, '["saved1", "saved2"]')

    visit project_issues_path(project_1, search: 'foo')

    items = all('.filtered-search-history-dropdown-item', visible: false, count: 3)

    expect(items[0].text).to eq('foo')
    expect(items[1].text).to eq('saved1')
    expect(items[2].text).to eq('saved2')
  end

  it 'searches are scoped to projects' do
    visit project_issues_path(project_1)

    input_filtered_search('foo', submit: true)
    input_filtered_search('bar', submit: true)

    visit project_issues_path(project_2)

    input_filtered_search('more', submit: true)
    input_filtered_search('things', submit: true)

    items = all('.filtered-search-history-dropdown-item', visible: false, count: 2)

    expect(items[0].text).to eq('things')
    expect(items[1].text).to eq('more')
  end

  it 'clicking item fills search input' do
    set_recent_searches(project_1_local_storage_key, '["foo", "bar"]')
    visit project_issues_path(project_1)

    find('.filtered-search-history-dropdown-toggle-button').click
    all('.filtered-search-history-dropdown-item', count: 2)[0].click
    wait_for_filtered_search('foo')

    expect(find('.filtered-search').value.strip).to eq('foo')
  end

  it 'clear recent searches button, clears recent searches' do
    set_recent_searches(project_1_local_storage_key, '["foo"]')
    visit project_issues_path(project_1)

    find('.filtered-search-history-dropdown-toggle-button').click
    all('.filtered-search-history-dropdown-item', count: 1)

    find('.filtered-search-history-clear-button').click
    items_after = all('.filtered-search-history-dropdown-item', count: 0)

    expect(items_after.count).to eq(0)
  end

  it 'shows flash error when failed to parse saved history' do
    set_recent_searches(project_1_local_storage_key, 'fail')
    visit project_issues_path(project_1)

    expect(find('.flash-alert')).to have_text('An error occurred while parsing recent searches')
  end

  context 'on tablet/mobile screen' do
    it 'shows only the history icon in the dropdown' do
      resize_screen_sm
      visit project_issues_path(project_1)

      expect(find('.filtered-search-history-dropdown-wrapper')).to have_selector('svg', visible: true)
      expect(find('.filtered-search-history-dropdown-wrapper')).to have_selector('span', text: 'Recent searches', visible: false)
    end
  end

  context 'on PC screen' do
    it 'shows only the Recent searches text in the dropdown' do
      restore_window_size
      visit project_issues_path(project_1)

      expect(find('.filtered-search-history-dropdown-wrapper')).to have_selector('svg', visible: false)
      expect(find('.filtered-search-history-dropdown-wrapper')).to have_selector('span', text: 'Recent searches', visible: true)
    end
  end
end
