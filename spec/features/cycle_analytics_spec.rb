# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Value Stream Analytics', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:stage_table_selector) { '[data-testid="vsa-stage-table"]' }
  let_it_be(:metrics_selector) { "[data-testid='vsa-time-metrics']" }

  let(:issue) { create(:issue, project: project, created_at: 2.days.ago) }
  let(:milestone) { create(:milestone, project: project) }
  let(:mr) { create_merge_request_closing_issue(user, project, issue, commit_message: "References #{issue.to_reference}") }
  let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha, head_pipeline_of: mr) }

  context 'as an allowed user' do
    context 'when project is new' do
      before(:all) do
        project.add_maintainer(user)
      end

      before do
        sign_in(user)

        visit project_cycle_analytics_path(project)
        wait_for_requests
      end

      it 'displays metrics' do
        aggregate_failures 'with relevant values' do
          expect(new_issues_counter).to have_content('-')
          expect(commits_counter).to have_content('-')
          expect(deploys_counter).to have_content('-')
          expect(deployment_frequency_counter).to have_content('-')
        end
      end

      it 'shows active stage with empty message' do
        expect(page).to have_selector('.gl-path-active-item-indigo', text: 'Issue')
        expect(page).to have_content("We don't have enough data to show this stage.")
      end
    end

    context "when there's value stream analytics data" do
      before do
        project.add_maintainer(user)

        @build = create_cycle(user, project, issue, mr, milestone, pipeline)
        deploy_master(user, project)

        issue.metrics.update!(first_mentioned_in_commit_at: issue.metrics.first_associated_with_milestone_at + 1.hour)
        merge_request = issue.merge_requests_closing_issues.first.merge_request
        merge_request.update!(created_at: issue.metrics.first_associated_with_milestone_at + 1.hour)
        merge_request.metrics.update!(
          latest_build_started_at: 4.hours.ago,
          latest_build_finished_at: 3.hours.ago,
          merged_at: merge_request.created_at + 1.hour,
          first_deployed_to_production_at: merge_request.created_at + 2.hours
        )

        sign_in(user)
        visit project_cycle_analytics_path(project)
      end

      it 'displays metrics' do
        metrics_tiles = page.find(metrics_selector)

        aggregate_failures 'with relevant values' do
          expect(metrics_tiles).to have_content('Commit')
          expect(metrics_tiles).to have_content('Deploy')
          expect(metrics_tiles).to have_content('Deployment Frequency')
          expect(metrics_tiles).to have_content('New Issue')
        end
      end

      it 'shows data on each stage', :sidekiq_might_not_need_inline do
        expect_issue_to_be_present

        click_stage('Plan')
        expect_issue_to_be_present

        click_stage('Code')
        expect_merge_request_to_be_present

        click_stage('Test')
        expect_merge_request_to_be_present

        click_stage('Review')
        expect_merge_request_to_be_present

        click_stage('Staging')
        expect_merge_request_to_be_present
      end

      context "when I change the time period observed" do
        before do
          _two_weeks_old_issue = create(:issue, project: project, created_at: 2.weeks.ago)

          click_button('Last 30 days')
          click_link('Last 7 days')
          wait_for_requests
        end

        it 'shows only relevant data' do
          expect(new_issue_counter).to have_content('1')
        end
      end
    end
  end

  context "as a guest" do
    before do
      project.add_developer(user)
      project.add_guest(guest)

      create_cycle(user, project, issue, mr, milestone, pipeline)
      deploy_master(user, project)

      sign_in(guest)
      visit project_cycle_analytics_path(project)
      wait_for_requests
    end

    it 'does not show the commit stats' do
      expect(page.find(metrics_selector)).not_to have_selector("#commits")
    end

    it 'needs permissions to see restricted stages' do
      expect(find(stage_table_selector)).to have_content(issue.title)

      click_stage('Code')
      expect(find(stage_table_selector)).to have_content('You need permission.')

      click_stage('Review')
      expect(find(stage_table_selector)).to have_content('You need permission.')
    end
  end

  def find_metric_tile(sel)
    page.find("#{metrics_selector} #{sel}")
  end

  # When now use proper pluralization for the metric names, which affects the id
  def new_issue_counter
    find_metric_tile("#new-issue")
  end

  def new_issues_counter
    find_metric_tile("#new-issues")
  end

  def commits_counter
    find_metric_tile("#commits")
  end

  def deploys_counter
    find_metric_tile("#deploys")
  end

  def deployment_frequency_counter
    find_metric_tile("#deployment-frequency")
  end

  def expect_issue_to_be_present
    expect(find(stage_table_selector)).to have_content(issue.title)
    expect(find(stage_table_selector)).to have_content(issue.author.name)
    expect(find(stage_table_selector)).to have_content("##{issue.iid}")
  end

  def expect_merge_request_to_be_present
    expect(find(stage_table_selector)).to have_content(mr.title)
    expect(find(stage_table_selector)).to have_content(mr.author.name)
    expect(find(stage_table_selector)).to have_content("!#{mr.iid}")
  end

  def click_stage(stage_name)
    find('.gl-path-nav-list-item', text: stage_name).click
    wait_for_requests
  end
end
