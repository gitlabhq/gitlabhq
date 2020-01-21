# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard Issues filtering', :js do
  include Spec::Support::Helpers::Features::SortingHelpers
  include FilteredSearchHelpers

  let(:user)      { create(:user) }
  let(:project)   { create(:project) }
  let(:milestone) { create(:milestone, project: project) }

  let!(:issue)  { create(:issue, project: project, author: user, assignees: [user]) }
  let!(:issue2) { create(:issue, project: project, author: user, assignees: [user], milestone: milestone) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit_issues
  end

  context 'without any filter' do
    it 'shows error message' do
      expect(page).to have_content 'Please select at least one filter to see results'
    end
  end

  context 'filtering by milestone' do
    it 'shows all issues with no milestone' do
      input_filtered_search("milestone=none")

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_selector('.issue', count: 1)
    end

    it 'shows all issues with the selected milestone' do
      input_filtered_search("milestone=%\"#{milestone.title}\"")

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_selector('.issue', count: 1)
    end

    it 'updates atom feed link' do
      visit_issues(milestone_title: '', assignee_username: user.username)

      link = find('.nav-controls a[title="Subscribe to RSS feed"]')
      params = CGI.parse(URI.parse(link[:href]).query)
      auto_discovery_link = find('link[type="application/atom+xml"]', visible: false)
      auto_discovery_params = CGI.parse(URI.parse(auto_discovery_link[:href]).query)

      expect(params).to include('feed_token' => [user.feed_token])
      expect(params).to include('milestone_title' => [''])
      expect(params).to include('assignee_username' => [user.username.to_s])
      expect(auto_discovery_params).to include('feed_token' => [user.feed_token])
      expect(auto_discovery_params).to include('milestone_title' => [''])
      expect(auto_discovery_params).to include('assignee_username' => [user.username.to_s])
    end
  end

  context 'filtering by label' do
    let(:label) { create(:label, project: project) }
    let!(:label_link) { create(:label_link, label: label, target: issue) }

    it 'shows all issues with the selected label' do
      input_filtered_search("label=~#{label.title}")

      page.within 'ul.content-list' do
        expect(page).to have_content issue.title
        expect(page).not_to have_content issue2.title
      end
    end
  end

  context 'sorting' do
    before do
      visit_issues(assignee_username: user.username)
    end

    it 'remembers last sorting value' do
      sort_by('Created date')
      visit_issues(assignee_username: user.username)

      expect(find('.issues-filters')).to have_content('Created date')
    end

    it 'keeps sorting issues after visiting Projects Issues page' do
      sort_by('Created date')
      visit project_issues_path(project)

      expect(find('.issues-filters')).to have_content('Created date')
    end
  end

  def visit_issues(*args)
    visit issues_dashboard_path(*args)
  end
end
