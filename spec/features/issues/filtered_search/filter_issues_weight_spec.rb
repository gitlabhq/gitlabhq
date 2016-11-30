require 'rails_helper'

describe 'Filter issues weight', js: true, feature: true do
  include WaitForAjax

  let!(:project) { create(:empty_project) }
  let!(:user) { create(:user, name: 'administrator', username: 'root') }
  let(:filtered_search) { find('.filtered-search') }
  let(:js_dropdown_weight) { '#js-dropdown-weight' }

  def input_filtered_search(search_term)
    filtered_search = find('.filtered-search')
    filtered_search.set(search_term)
    filtered_search.send_keys(:enter)
  end

  def expect_filtered_search_input(input)
    expect(find('.filtered-search').value).to eq(input)
  end

  def expect_issues_list_count(open_count, closed_count = 0)
    all_count = open_count + closed_count

    expect(page).to have_issuable_counts(open: open_count, closed: closed_count, all: all_count)
    page.within '.issues-list' do
      expect(page).to have_selector('.issue', count: open_count)
    end
  end

  before do
    project.team << [user, :master]
    login_as(user)

    label = create(:label, project: project, title: 'urgent')
    milestone = create(:milestone, title: 'version1', project: project)

    create(:issue, project: project, weight: 1)
    issue = create(:issue,
      project: project,
      weight: 2,
      title: 'Bug report 1',
      milestone: milestone,
      author: user,
      assignee: user)
    issue.labels << label

    visit namespace_project_issues_path(project.namespace, project)
  end

  describe 'only weight' do
    it 'filter issues by searched weight' do
      input_filtered_search('weight:1')

      expect_issues_list_count(1)
    end

    it 'filters issues by invalid weight' do
      skip('to be tested, issue #1517')
    end

    it 'filters issues by multiple weights' do
      skip('to be tested, issue #1517')
    end
  end

  describe 'weight with other filters' do
    it 'filters issues by searched weight and text' do
      search = "weight:2 bug"
      input_filtered_search(search)

      expect_issues_list_count(1)
      expect_filtered_search_input(search)
    end

    it 'filters issues by searched weight, author and text' do
      search = "weight:2 author:@root bug"
      input_filtered_search(search)

      expect_issues_list_count(1)
      expect_filtered_search_input(search)
    end

    it 'filters issues by searched weight, author, assignee and text' do
      search = "weight:2 author:@root assignee:@root bug"
      input_filtered_search(search)

      expect_issues_list_count(1)
      expect_filtered_search_input(search)
    end

    it 'filters issues by searched weight, author, assignee, label and text' do
      search = "weight:2 author:@root assignee:@root label:~urgent bug"
      input_filtered_search(search)

      expect_issues_list_count(1)
      expect_filtered_search_input(search)
    end

    it 'filters issues by searched weight, author, assignee, label, milestone and text' do
      search = "weight:2 author:@root assignee:@root label:~urgent milestone:%version1 bug"
      input_filtered_search(search)

      expect_issues_list_count(1)
      expect_filtered_search_input(search)
    end
  end
end
