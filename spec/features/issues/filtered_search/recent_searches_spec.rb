require 'spec_helper'

describe 'Recent searches', js: true, feature: true do
  include FilteredSearchHelpers

  let!(:group) { create(:group) }
  let!(:project) { create(:project, group: group) }
  let!(:user) { create(:user) }

  before do
    Capybara.ignore_hidden_elements = false
    project.add_master(user)
    group.add_developer(user)
    create(:issue, project: project)
    login_as(user)

    remove_recent_searches
  end

  after do
    Capybara.ignore_hidden_elements = true
  end

  it 'searching adds to recent searches' do
    visit namespace_project_issues_path(project.namespace, project)

    input_filtered_search('foo', submit: true)
    input_filtered_search('bar', submit: true)

    items = all('.filtered-search-history-dropdown-item', visible: false)

    expect(items.count).to eq(2)
    expect(items[0].text).to eq('bar')
    expect(items[1].text).to eq('foo')
  end

  it 'visiting URL with search params adds to recent searches' do
    visit namespace_project_issues_path(project.namespace, project, label_name: 'foo', search: 'bar')
    visit namespace_project_issues_path(project.namespace, project, label_name: 'qux', search: 'garply')

    items = all('.filtered-search-history-dropdown-item', visible: false)

    expect(items.count).to eq(2)
    expect(items[0].text).to eq('label:~qux garply')
    expect(items[1].text).to eq('label:~foo bar')
  end

  it 'saved recent searches are restored last on the list' do
    set_recent_searches('["saved1", "saved2"]')

    visit namespace_project_issues_path(project.namespace, project, search: 'foo')

    items = all('.filtered-search-history-dropdown-item', visible: false)

    expect(items.count).to eq(3)
    expect(items[0].text).to eq('foo')
    expect(items[1].text).to eq('saved1')
    expect(items[2].text).to eq('saved2')
  end

  it 'clicking item fills search input' do
    set_recent_searches('["foo", "bar"]')
    visit namespace_project_issues_path(project.namespace, project)

    all('.filtered-search-history-dropdown-item', visible: false)[0].trigger('click')
    wait_for_filtered_search('foo')

    expect(find('.filtered-search').value.strip).to eq('foo')
  end

  it 'clear recent searches button, clears recent searches' do
    set_recent_searches('["foo"]')
    visit namespace_project_issues_path(project.namespace, project)

    items_before = all('.filtered-search-history-dropdown-item', visible: false)

    expect(items_before.count).to eq(1)

    find('.filtered-search-history-clear-button', visible: false).trigger('click')
    items_after = all('.filtered-search-history-dropdown-item', visible: false)

    expect(items_after.count).to eq(0)
  end

  it 'shows flash error when failed to parse saved history' do
    set_recent_searches('fail')
    visit namespace_project_issues_path(project.namespace, project)

    expect(find('.flash-alert')).to have_text('An error occured while parsing recent searches')
  end
end
