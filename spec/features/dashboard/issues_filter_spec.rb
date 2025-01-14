# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard Issues filtering', :js, feature_category: :team_planning do
  include Features::SortingHelpers
  include FilteredSearchHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:milestone) { create(:milestone, project: project) }

  let_it_be(:issue) { create(:issue, project: project, author: user, assignees: [user]) }
  let_it_be(:issue2) { create(:issue, project: project, author: user, assignees: [user], milestone: milestone) }
  let_it_be(:label) { create(:label, project: project, title: 'bug') }
  let_it_be(:label_link) { create(:label_link, label: label, target: issue) }

  let_it_be(:project2) { create(:project, namespace: user.namespace) }
  let_it_be(:label2) { create(:label, title: 'bug') }

  before do
    project.labels << label
    project2.labels << label2
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'without any filter' do
    it 'shows error message' do
      visit issues_dashboard_path

      expect(page).to have_content 'Please select at least one filter to see results'
    end
  end

  context 'filtering by milestone' do
    it 'shows all issues with no milestone' do
      visit issues_dashboard_path

      select_tokens 'Milestone', '=', 'None', submit: true

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_selector('.issue', count: 1)
    end

    it 'shows all issues with the selected milestone' do
      visit issues_dashboard_path

      select_tokens 'Milestone', '=', milestone.title, submit: true

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_selector('.issue', count: 1)
    end

    it 'updates atom feed link' do
      visit issues_dashboard_path(milestone_title: '', assignee_username: user.username)
      click_button 'Actions'

      link = find_link('Subscribe to RSS feed')
      params = CGI.parse(URI.parse(link[:href]).query)
      auto_discovery_link = find('link[type="application/atom+xml"]', visible: false)
      auto_discovery_params = CGI.parse(URI.parse(auto_discovery_link[:href]).query)

      feed_token_param = params['feed_token']
      expect(feed_token_param).to match([Gitlab::Auth::AuthFinders::PATH_DEPENDENT_FEED_TOKEN_REGEX])
      expect(feed_token_param.first).to end_with(user.id.to_s)
      expect(params).to include('milestone_title' => [''])
      expect(params).to include('assignee_username' => [user.username.to_s])

      feed_token_param = auto_discovery_params['feed_token']
      expect(feed_token_param).to match([Gitlab::Auth::AuthFinders::PATH_DEPENDENT_FEED_TOKEN_REGEX])
      expect(feed_token_param.first).to end_with(user.id.to_s)
      expect(auto_discovery_params).to include('milestone_title' => [''])
      expect(auto_discovery_params).to include('assignee_username' => [user.username.to_s])
    end
  end

  context 'filtering by label' do
    before do
      visit issues_dashboard_path
    end

    it 'shows all issues with the selected label' do
      select_tokens 'Label', '=', label.title, submit: true

      expect(page).to have_content issue.title
      expect(page).not_to have_content issue2.title
    end

    it 'removes duplicate labels' do
      select_tokens 'Label', '='
      send_keys 'bu'

      expect_suggestion('bug')
      expect_suggestion_count(3) # Expect None, Any, and bug
    end
  end

  context 'sorting' do
    before do
      visit issues_dashboard_path(assignee_username: user.username)
    end

    it 'remembers last sorting value', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/408749' do
      click_button 'Created date'
      click_button 'Updated date'

      visit issues_dashboard_path(assignee_username: user.username)

      expect(page).to have_button('Updated date')
    end

    it 'keeps sorting issues after visiting Projects Issues page',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/480735' do
      pajamas_sort_by 'Due date', from: 'Created date'

      visit project_issues_path(project)

      expect(page).to have_button('Due date')
    end
  end
end
