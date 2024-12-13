# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Value Stream Analytics', :js, feature_category: :value_stream_management do
  include CycleAnalyticsHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:stage_table_selector) { '[data-testid="vsa-stage-table"]' }
  let_it_be(:stage_filter_bar) { '[data-testid="vsa-filter-bar"]' }
  let_it_be(:stage_table_event_selector) { '[data-testid="vsa-stage-event"]' }
  let_it_be(:stage_table_event_title_selector) { '[data-testid="vsa-stage-event-title"]' }
  let_it_be(:stage_table_pagination_selector) { '[data-testid="vsa-stage-pagination"]' }
  let_it_be(:stage_table_duration_column_header_selector) { '[data-testid="vsa-stage-header-duration"]' }
  let_it_be(:metrics_selector) { "[data-testid='vsa-metrics']" }
  let_it_be(:predefined_date_ranges_dropdown_selector) { '[data-testid="vsa-predefined-date-ranges-dropdown"]' }
  let_it_be(:project) { create(:project, :repository, maintainers: user) }
  let_it_be(:issue) { create(:issue, title: 'My feature', project: project, created_at: 3.weeks.ago) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:mr) { create(:merge_request, source_project: project) }
  let_it_be(:commit) { create_commit("References #{issue.to_reference}", project, user, mr.source_branch, commit_time: mr.created_at - 1.day, skip_push_handler: true) }
  let_it_be(:closed_issues) { create(:merge_requests_closing_issues, merge_request: mr, issue_id: issue.id) }
  let_it_be(:pipeline) do
    create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha, head_pipeline_of: mr)
  end

  let(:stage_table) { find(stage_table_selector) }

  def set_daterange(from_date, to_date)
    page.find(".js-daterange-picker-from input").set(from_date)
    page.find(".js-daterange-picker-to input").set(to_date)

    # simulate a blur event
    page.find(".js-daterange-picker-to input").send_keys(:tab)
    wait_for_all_requests
  end

  context 'as an allowed user' do
    context 'when project is new' do
      before do
        sign_in(user)

        visit project_cycle_analytics_path(project)
        wait_for_requests
      end

      it 'displays metrics with relevant values' do
        new_issue_count, commit_count, deploy_count = vsa_metrics_values

        # We expect 1 for new issues because we created one in the setup
        expect(new_issue_count).to eq("1")

        # We expect 1 commit because we created one commit in the setup
        expect(commit_count).to eq("1")

        # No deploys were made to master in the time period
        expect(deploy_count).to eq("-")
      end

      it 'shows active stage with empty message' do
        expect(page).to have_selector('.gl-path-active-item', text: 'Issue')
        expect(page).to have_content("There are 0 items to show in this stage, for these filters, within this time range.")
      end
    end

    context "when there's value stream analytics data", :sidekiq_inline do
      # NOTE: in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68595 travel back
      # 5 days in time before we create data for these specs, to mitigate some flakiness
      # So setting the date range to be the last 2 days should skip past the existing data
      from = 2.days.ago.utc.to_date.iso8601
      to = 1.day.ago.utc.to_date.iso8601
      max_items_per_page = 3

      around do |example|
        travel_to(5.days.ago.utc) { example.run }
      end

      before_all do
        # travel_to Time.now.utc
        travel_to(5.days.ago.utc) do
          create_cycle(user, project, issue, mr, milestone, pipeline)
          create_list(:issue, max_items_per_page, project: project, created_at: 2.weeks.ago, milestone: milestone)
          deploy_master(user, project)

          issue.reload.metrics.update!(first_mentioned_in_commit_at: issue.metrics.first_associated_with_milestone_at + 1.hour)
          mr.update!(created_at: issue.metrics.first_associated_with_milestone_at + 1.hour)
          mr.metrics.update!(
            latest_build_started_at: mr.created_at + 3.hours,
            latest_build_finished_at: mr.created_at + 4.hours,
            merged_at: mr.created_at + 4.hours,
            first_deployed_to_production_at: mr.created_at + 5.hours
          )
        end
      end

      before do
        stub_const('Gitlab::Analytics::CycleAnalytics::RecordsFetcher::MAX_RECORDS', max_items_per_page - 1)
        sign_in(user)
        visit project_cycle_analytics_path(project)

        wait_for_requests
      end

      let(:stage_table_events) { stage_table.all(stage_table_event_selector) }

      it 'displays metrics' do
        expect(page).to have_selector metrics_selector

        aggregate_failures 'with relevant values' do
          expect(vsa_metrics_titles.length).to eq 3
          expect(vsa_metrics_titles).to match_array ['New issues', 'Commits', 'Deploys']

          expect(vsa_metrics_values).to match_array %w[4 - -]
        end
      end

      it 'shows data on each stage', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/509194' do
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

      it 'can sort records' do
        original_first_title = issue.title

        expect_to_be_sorted "descending"
        expect(first_stage_title).to eq(original_first_title)

        stage_time_column.click

        expect_to_be_sorted "ascending"
        expect(first_stage_title).not_to eq(original_first_title)
      end

      it 'paginates the results' do
        original_first_title = first_stage_title

        expect(page).to have_selector(stage_table_pagination_selector)

        go_to_next_page

        expect(page).not_to have_text(original_first_title, exact: true)
      end

      it 'shows predefined date ranges dropdown with `Custom` option selected' do
        page.within(predefined_date_ranges_dropdown_selector) do
          expect(page).to have_button('Custom')
        end
      end

      it 'can filter the issues by date' do
        expect(page).to have_selector(stage_table_event_selector)

        set_daterange(from, to)

        expect(page).not_to have_selector(stage_table_event_selector)
        expect(page).not_to have_selector(stage_table_pagination_selector)
      end

      it 'can filter the metrics by date' do
        expect(vsa_metrics_values).to match_array(%w[- - 4])

        set_daterange(from, to)

        expect(vsa_metrics_values).to eq(['-'] * 3)
      end

      it 'can navigate directly to a value stream stream stage with filters applied' do
        visit project_cycle_analytics_path(project, created_before: '2019-12-31', created_after: '2019-11-01', stage_id: 'code', milestone_title: milestone.title)
        wait_for_requests

        expect(page).to have_selector('.gl-path-active-item', text: 'Code')
        expect(page.find(".js-daterange-picker-from input").value).to eq("2019-11-01")
        expect(page.find(".js-daterange-picker-to input").value).to eq("2019-12-31")

        filter_bar = page.find(stage_filter_bar)
        expect(filter_bar.find(".gl-filtered-search-token-data-content").text).to eq("%#{milestone.title}")
      end

      def stage_time_column
        stage_table.find(stage_table_duration_column_header_selector).ancestor("th")
      end

      def first_stage_title
        stage_table.all(stage_table_event_title_selector).first.text
      end

      def expect_to_be_sorted(direction)
        expect(stage_time_column['aria-sort']).to eq(direction)
      end

      def go_to_next_page
        page.find(stage_table_pagination_selector).find_link("Next").click
      end
    end
  end

  context "as a guest" do
    before_all do
      project.add_guest(guest)

      create_cycle(user, project, issue, mr, milestone, pipeline)
      deploy_master(user, project)
    end

    before do
      sign_in(guest)
      visit project_cycle_analytics_path(project)
      wait_for_requests
    end

    it 'does not show the commit stats', :sidekiq_inline do
      expect(page.find(metrics_selector)).not_to have_selector("#commits")
    end

    it 'displays metrics' do
      expect(page).to have_selector metrics_selector

      aggregate_failures 'with relevant values' do
        expect(vsa_metrics_titles.length).to eq 2
        expect(vsa_metrics_titles).to match_array ['New issues', 'Deploys']

        expect(vsa_metrics_values).to match_array %w[- 1]
      end
    end

    it 'does not show restricted stages', :aggregate_failures, :sidekiq_inline do
      expect(find(stage_table_selector)).to have_content(issue.title)

      expect(page).to have_selector('.gl-path-nav-list-item', text: 'Issue')

      expect(page).to have_selector('.gl-path-nav-list-item', text: 'Plan')

      expect(page).to have_selector('.gl-path-nav-list-item', text: 'Test')

      expect(page).to have_selector('.gl-path-nav-list-item', text: 'Staging')

      expect(page).not_to have_selector('.gl-path-nav-list-item', text: 'Code')

      expect(page).not_to have_selector('.gl-path-nav-list-item', text: 'Review')
    end
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
