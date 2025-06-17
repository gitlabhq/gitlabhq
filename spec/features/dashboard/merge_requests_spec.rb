# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard Merge Requests', :js, feature_category: :code_review_workflow do
  include Features::SortingHelpers
  include FilteredSearchHelpers
  include ProjectForksHelper

  let(:current_user) { create(:user) }
  let(:user) { current_user }
  let(:project) { create(:project) }

  let(:public_project) { create(:project, :public, :repository) }
  let(:forked_project) { fork_project(public_project, current_user, repository: true) }
  let(:page_path) { merge_requests_dashboard_path(assignee_username: [user.username]) }

  before do
    project.add_maintainer(current_user)
    sign_in(current_user)
  end

  context 'when the test is flaky',
    quarantine: {
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/535181',
      type: :flaky
    } do
    it_behaves_like 'page with product usage data collection banner'
  end

  describe 'sidebar' do
    it 'has nav items for assigned MRs and review requests' do
      visit merge_requests_dashboard_path(assignee_username: user)

      within('#super-sidebar') do
        expect(page).to have_css("a[data-track-label='merge_requests_assigned'][aria-current='page']")
      end

      click_link 'Review requests'

      within('#super-sidebar') do
        expect(page).to have_css("a[data-track-label='merge_requests_to_review'][aria-current='page']")
      end
    end
  end

  it 'disables target branch filter' do
    visit merge_requests_dashboard_path

    expect(page).not_to have_selector('#js-dropdown-target-branch', visible: false)
  end

  it 'disables releases filter' do
    visit merge_requests_dashboard_path

    expect(page).not_to have_selector('#js-dropdown-release', visible: false)
  end

  it 'disables environments filter' do
    visit merge_requests_dashboard_path

    expect(page).not_to have_selector('#js-dropdown-environment', visible: false)
  end

  context 'new merge request dropdown' do
    let(:project_with_disabled_merge_requests) { create(:project, :merge_requests_disabled) }

    before do
      project_with_disabled_merge_requests.add_maintainer(current_user)
      visit merge_requests_dashboard_path
    end

    it 'shows projects only with merge requests feature enabled' do
      click_button 'Select project to create merge request'
      wait_for_requests

      within_testid('new-resource-dropdown') do
        expect(page).to have_content(project.full_name)
        expect(page).not_to have_content(project_with_disabled_merge_requests.full_name)

        find_button(project.full_name).click

        expect(page).to have_link("New merge request in #{project.name}")
      end
    end

    it 'passes axe automated accessibility testing' do
      expect(page).to be_axe_clean.within('#content-body')
    end
  end

  context 'no merge requests exist' do
    before do
      visit merge_requests_dashboard_path(assignee_username: current_user.username)
    end

    it 'shows an empty state' do
      expect(page).to have_selector('.gl-empty-state')
    end

    it 'passes axe automated accessibility testing' do
      expect(page).to be_axe_clean.within('#content-body')
    end
  end

  context 'merge requests exist' do
    let_it_be(:author_user) { create(:user) }

    let(:label) { create(:label) }

    let!(:assigned_merge_request) do
      create(:merge_request,
        assignees: [current_user],
        source_project: project,
        author: author_user)
    end

    let!(:review_requested_merge_request) do
      create(:merge_request,
        reviewers: [current_user],
        source_branch: 'review',
        source_project: project,
        author: author_user)
    end

    let!(:assigned_merge_request_from_fork) do
      create(
        :merge_request,
        source_branch: 'markdown',
        assignees: [current_user],
        target_project: public_project,
        source_project: forked_project,
        author: author_user
      )
    end

    let!(:authored_merge_request) do
      create(
        :merge_request,
        source_branch: 'markdown',
        source_project: project,
        author: current_user
      )
    end

    let!(:authored_merge_request_from_fork) do
      create(
        :merge_request,
        source_branch: 'feature_conflict',
        author: current_user,
        target_project: public_project,
        source_project: forked_project
      )
    end

    let!(:labeled_merge_request) do
      create(
        :labeled_merge_request,
        source_branch: 'labeled',
        labels: [label],
        author: current_user,
        source_project: project
      )
    end

    let!(:detailed_merge_request) do
      create(
        :merge_request,
        source_branch: 'accessibility_fix',
        assignees: [current_user],
        target_project: public_project,
        source_project: forked_project,
        author: author_user,
        reviewers: [current_user],
        labels: [label]
      )
    end

    let!(:other_merge_request) do
      create(
        :merge_request,
        source_branch: 'fix',
        source_project: project,
        author: author_user
      )
    end

    before do
      visit merge_requests_dashboard_path(assignee_username: current_user.username)
    end

    it 'includes assigned and reviewers in badge' do
      within('#merge-requests') do
        expect(page).to have_css("a", text: 'Assigned 3')
        expect(page).to have_css("a", text: 'Review requests 2')
      end
    end

    it 'shows assigned merge requests' do
      expect(page).to have_content(assigned_merge_request.title)
      expect(page).to have_content(assigned_merge_request_from_fork.title)

      expect(page).not_to have_content(authored_merge_request.title)
      expect(page).not_to have_content(authored_merge_request_from_fork.title)
      expect(page).not_to have_content(other_merge_request.title)
      expect(page).not_to have_content(labeled_merge_request.title)
    end

    it 'does not show review requested merge requests' do
      expect(page).not_to have_content(review_requested_merge_request.title)
    end

    it 'shows authored merge requests' do
      reset_filters
      input_filtered_search("author:=#{current_user.to_reference}")

      expect(page).to have_content(authored_merge_request.title)
      expect(page).to have_content(authored_merge_request_from_fork.title)
      expect(page).to have_content(labeled_merge_request.title)

      expect(page).not_to have_content(assigned_merge_request.title)
      expect(page).not_to have_content(assigned_merge_request_from_fork.title)
      expect(page).not_to have_content(other_merge_request.title)
    end

    it 'shows labeled merge requests' do
      reset_filters
      input_filtered_search("label:=#{label.name}")

      expect(page).to have_content(labeled_merge_request.title)

      expect(page).not_to have_content(authored_merge_request.title)
      expect(page).not_to have_content(authored_merge_request_from_fork.title)
      expect(page).not_to have_content(assigned_merge_request.title)
      expect(page).not_to have_content(assigned_merge_request_from_fork.title)
      expect(page).not_to have_content(other_merge_request.title)
    end

    it 'shows error message without filter' do
      reset_filters

      expect(page).to have_content('Please select at least one filter to see results')
    end

    it 'shows sorted merge requests' do
      pajamas_sort_by(s_('SortOptions|Priority'), from: s_('SortOptions|Created date'))

      visit merge_requests_dashboard_path(assignee_username: current_user.username)

      expect(find('.issues-filters')).to have_content(s_('SortOptions|Priority'))
    end

    it 'keeps sorting merge requests after visiting Projects MR page' do
      pajamas_sort_by(s_('SortOptions|Priority'), from: s_('SortOptions|Created date'))

      visit project_merge_requests_path(project)

      expect(find_by_testid('issuable-search-container')).to have_content(s_('SortOptions|Priority'))
    end

    it 'passes axe automated accessibility testing' do
      expect(page).to be_axe_clean.within('#content-body')
    end
  end

  context 'merge request review' do
    let_it_be(:author_user) { create(:user) }

    let!(:review_requested_merge_request) do
      create(:merge_request,
        reviewers: [current_user],
        source_branch: 'review',
        source_project: project,
        author: author_user)
    end

    before do
      visit merge_requests_dashboard_path(reviewer_username: current_user.username)
    end

    it 'displays review requested merge requests' do
      expect(page).to have_content(review_requested_merge_request.title)

      expect_tokens([reviewer_token(current_user.name)])
    end
  end
end
