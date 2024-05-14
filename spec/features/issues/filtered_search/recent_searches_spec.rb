# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Recent searches', :js, feature_category: :team_planning do
  include FilteredSearchHelpers

  let_it_be(:project_1) { create(:project, :public) }
  let_it_be(:project_2) { create(:project, :public) }
  let_it_be(:issue_1) { create(:issue, project: project_1) }
  let_it_be(:issue_2) { create(:issue, project: project_2) }

  let(:project_1_local_storage_key) { "#{project_1.full_path}-issue-recent-searches" }

  before do
    # Visit any fast-loading page so we can clear local storage without a DOM exception
    visit '/404'
    remove_recent_searches
  end

  it 'searching adds to recent searches' do
    visit project_issues_path(project_1)

    submit_then_clear_search 'foo'
    submit_then_clear_search 'bar'
    click_button 'Toggle history'

    expect_recent_searches_history_item 'bar'
    expect_recent_searches_history_item 'foo'
  end

  it 'visiting URL with search params adds to recent searches' do
    visit project_issues_path(project_1, label_name: 'foo', search: 'bar')
    visit project_issues_path(project_1, label_name: 'qux', search: 'garply')

    click_button 'Toggle history'

    expect_recent_searches_history_item 'Label := qux garply'
    expect_recent_searches_history_item 'Label := foo bar'
  end

  it 'saved recent searches are restored last on the list' do
    set_recent_searches(project_1_local_storage_key, '[[{"type":"filtered-search-term","value":{"data":"saved1"}}],[{"type":"filtered-search-term","value":{"data":"saved2"}}]]')

    visit project_issues_path(project_1, search: 'foo')
    click_button 'Toggle history'

    expect_recent_searches_history_item 'foo'
    expect_recent_searches_history_item 'saved1'
    expect_recent_searches_history_item 'saved2'
  end

  it 'searches are scoped to projects' do
    visit project_issues_path(project_1)

    submit_then_clear_search 'foo'
    submit_then_clear_search 'bar'

    visit project_issues_path(project_2)

    submit_then_clear_search 'more'
    submit_then_clear_search 'things'
    click_button 'Toggle history'

    expect_recent_searches_history_item 'things'
    expect_recent_searches_history_item 'more'
  end

  it 'clicking item fills search input' do
    set_recent_searches(project_1_local_storage_key, '[[{"type":"filtered-search-term","value":{"data":"foo"}}],[{"type":"filtered-search-term","value":{"data":"bar"}}]]')
    visit project_issues_path(project_1)

    click_button 'Toggle history'
    click_button 'foo'

    expect_search_term 'foo'
  end

  it 'clear recent searches button, clears recent searches' do
    set_recent_searches(project_1_local_storage_key, '[[{"type":"filtered-search-term","value":{"data":"foo"}}]]')
    visit project_issues_path(project_1)

    click_button 'Toggle history'

    expect_recent_searches_history_item_count 1

    click_button 'Clear recent searches'

    expect(page).to have_text "You don't have any recent searches"
    expect_recent_searches_history_item_count 0
  end

  it 'shows flash error when failed to parse saved history' do
    set_recent_searches(project_1_local_storage_key, 'fail')
    visit project_issues_path(project_1)

    expect(page).to have_text 'An error occurred while parsing recent searches'
  end

  def submit_then_clear_search(search)
    click_filtered_search_bar
    send_keys(search, :enter, :enter)
    click_button 'Clear'
  end
end
