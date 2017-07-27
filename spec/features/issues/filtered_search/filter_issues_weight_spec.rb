require 'rails_helper'

describe 'Filter issues weight', js: true, feature: true do
  include FilteredSearchHelpers

  let!(:project) { create(:empty_project) }
  let!(:user) { create(:user, name: 'administrator', username: 'root') }
  let(:js_dropdown_weight) { '#js-dropdown-weight' }

  def expect_issues_list_count(open_count, closed_count = 0)
    all_count = open_count + closed_count

    expect(page).to have_issuable_counts(open: open_count, closed: closed_count, all: all_count)
    page.within '.issues-list' do
      expect(page).to have_selector('.issue', count: open_count)
    end
  end

  before do
    project.team << [user, :master]
    sign_in(user)

    label = create(:label, project: project, title: 'urgent')
    milestone = create(:milestone, title: 'version1', project: project)

    create(:issue, project: project, weight: 1)
    issue = create(:issue,
      project: project,
      weight: 2,
      title: 'Bug report 1',
      milestone: milestone,
      author: user,
      assignees: [user])
    issue.labels << label

    visit project_issues_path(project)
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
      expect_filtered_search_input('bug')
    end

    it 'filters issues by searched weight, author and text' do
      search = "weight:2 author:@root bug"
      input_filtered_search(search)

      expect_issues_list_count(1)
      expect_filtered_search_input('bug')
    end

    it 'filters issues by searched weight, author, assignee and text' do
      search = "weight:2 author:@root assignee:@root bug"
      input_filtered_search(search)

      expect_issues_list_count(1)
      expect_filtered_search_input('bug')
    end

    it 'filters issues by searched weight, author, assignee, label and text' do
      search = "weight:2 author:@root assignee:@root label:~urgent bug"
      input_filtered_search(search)

      expect_issues_list_count(1)
      expect_filtered_search_input('bug')
    end

    it 'filters issues by searched weight, milestone and text' do
      search = "weight:2 milestone:%version1 bug"
      input_filtered_search(search)

      expect_issues_list_count(1)
      expect_filtered_search_input('bug')
    end
  end
end
