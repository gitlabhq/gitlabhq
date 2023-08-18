# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin::AbuseReports", :js, feature_category: :insider_threat do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }

  let_it_be(:open_report) { create(:abuse_report, created_at: 5.days.ago, updated_at: 2.days.ago, category: 'spam', user: user) }
  let_it_be(:open_report2) { create(:abuse_report, created_at: 4.days.ago, updated_at: 3.days.ago, category: 'phishing') }
  let_it_be(:closed_report) { create(:abuse_report, :closed, user: user, category: 'spam') }

  describe 'as an admin' do
    before do
      sign_in(admin)
      gitlab_enable_admin_mode_sign_in(admin)
    end

    context 'when abuse_reports_list feature flag is enabled' do
      include FilteredSearchHelpers

      before do
        visit admin_abuse_reports_path
      end

      let(:abuse_report_row_selector) { '[data-testid="abuse-report-row"]' }

      it 'only includes open reports by default' do
        expect_displayed_reports_count(2)

        expect_report_shown(open_report, open_report2)

        within '[data-testid="abuse-reports-filtered-search-bar"]' do
          expect(page).to have_content 'Status = Open'
        end
      end

      it 'can be filtered by status, user, reporter, and category', :aggregate_failures do
        # filter by status
        filter %w[Status Closed]
        expect_displayed_reports_count(1)
        expect_report_shown(closed_report)
        expect_report_not_shown(open_report, open_report2)

        filter %w[Status Open]
        expect_displayed_reports_count(2)
        expect_report_shown(open_report, open_report2)
        expect_report_not_shown(closed_report)

        # filter by user
        filter(['User', open_report2.user.username])

        expect_displayed_reports_count(1)
        expect_report_shown(open_report2)
        expect_report_not_shown(open_report, closed_report)

        # filter by reporter
        filter(['Reporter', open_report.reporter.username])

        expect_displayed_reports_count(1)
        expect_report_shown(open_report)
        expect_report_not_shown(open_report2, closed_report)

        # filter by category
        filter(['Category', open_report2.category])

        expect_displayed_reports_count(1)
        expect_report_shown(open_report2)
        expect_report_not_shown(open_report, closed_report)
      end

      it 'can be sorted by created_at and updated_at in desc and asc order', :aggregate_failures do
        sort_by 'Created date'
        # created_at desc
        expect(report_rows[0].text).to include(report_text(open_report2))
        expect(report_rows[1].text).to include(report_text(open_report))

        # created_at asc
        toggle_sort_direction

        expect(report_rows[0].text).to include(report_text(open_report))
        expect(report_rows[1].text).to include(report_text(open_report2))

        # updated_at asc
        sort_by 'Updated date'

        expect(report_rows[0].text).to include(report_text(open_report2))
        expect(report_rows[1].text).to include(report_text(open_report))

        # updated_at desc
        toggle_sort_direction

        expect(report_rows[0].text).to include(report_text(open_report))
        expect(report_rows[1].text).to include(report_text(open_report2))
      end

      context 'when multiple reports for the same user are created' do
        let_it_be(:open_report3) { create(:abuse_report, category: 'spam', user: user) }
        let_it_be(:closed_report2) { create(:abuse_report, :closed, user: user, category: 'spam') }

        it 'aggregates open reports by user & category', :aggregate_failures do
          expect_displayed_reports_count(2)

          expect_aggregated_report_shown(open_report, 2)
          expect_report_shown(open_report2)
        end

        it 'can sort aggregated reports by number_of_reports in desc order only', :aggregate_failures do
          sort_by 'Number of Reports'

          expect(report_rows[0].text).to include(aggregated_report_text(open_report, 2))
          expect(report_rows[1].text).to include(report_text(open_report2))

          toggle_sort_direction

          expect(report_rows[0].text).to include(aggregated_report_text(open_report, 2))
          expect(report_rows[1].text).to include(report_text(open_report2))
        end

        it 'can sort aggregated reports by created_at and updated_at in desc and asc order', :aggregate_failures do
          # number_of_reports desc (default)
          expect(report_rows[0].text).to include(aggregated_report_text(open_report, 2))
          expect(report_rows[1].text).to include(report_text(open_report2))

          # created_at desc
          sort_by 'Created date'

          expect(report_rows[0].text).to include(report_text(open_report2))
          expect(report_rows[1].text).to include(aggregated_report_text(open_report, 2))

          # created_at asc
          toggle_sort_direction

          expect(report_rows[0].text).to include(aggregated_report_text(open_report, 2))
          expect(report_rows[1].text).to include(report_text(open_report2))

          sort_by 'Updated date'

          # updated_at asc
          expect(report_rows[0].text).to include(report_text(open_report2))
          expect(report_rows[1].text).to include(aggregated_report_text(open_report, 2))

          # updated_at desc
          toggle_sort_direction

          expect(report_rows[0].text).to include(aggregated_report_text(open_report, 2))
          expect(report_rows[1].text).to include(report_text(open_report2))
        end

        it 'does not aggregate closed reports', :aggregate_failures do
          filter %w[Status Closed]

          expect_displayed_reports_count(2)
          expect_report_shown(closed_report, closed_report2)
        end
      end

      def report_rows
        page.all(abuse_report_row_selector)
      end

      def report_text(report)
        "#{report.user.name} reported for #{report.category} by #{report.reporter.name}"
      end

      def aggregated_report_text(report, count)
        "#{report.user.name} reported for #{report.category} by #{count} users"
      end

      def expect_report_shown(*reports)
        reports.each do |r|
          expect(page).to have_content(report_text(r))
        end
      end

      def expect_report_not_shown(*reports)
        reports.each do |r|
          expect(page).not_to have_content(report_text(r))
        end
      end

      def expect_aggregated_report_shown(*reports, count)
        reports.each do |r|
          expect(page).to have_content(aggregated_report_text(r, count))
        end
      end

      def expect_displayed_reports_count(count)
        expect(page).to have_css(abuse_report_row_selector, count: count)
      end

      def filter(tokens)
        # remove all existing filters first
        page.find_all('.gl-token-close').each(&:click)

        select_tokens(*tokens, submit: true, input_text: 'Filter reports')
      end

      def sort_by(sort)
        page.within('.vue-filtered-search-bar-container .sort-dropdown-container') do
          page.find('.gl-dropdown-toggle').click

          page.within('.dropdown-menu') do
            click_button sort
            wait_for_requests
          end
        end
      end
    end

    context 'when abuse_reports_list feature flag is disabled' do
      before do
        stub_feature_flags(abuse_reports_list: false)

        visit admin_abuse_reports_path
      end

      it 'displays all abuse reports', :aggregate_failures do
        expect_report_shown(open_report)
        expect_report_actions_shown(open_report)

        expect_report_shown(open_report2)
        expect_report_actions_shown(open_report2)

        expect_report_shown(closed_report)
        expect_report_actions_shown(closed_report)
      end

      context 'when an admin has been reported for abuse' do
        let_it_be(:admin_abuse_report) { create(:abuse_report, user: admin) }

        it 'displays the abuse report without actions' do
          expect_report_shown(admin_abuse_report)
          expect_report_actions_not_shown(admin_abuse_report)
        end
      end

      context 'when multiple users have been reported for abuse' do
        let(:report_count) { AbuseReport.default_per_page + 3 }

        before do
          report_count.times do
            create(:abuse_report, user: create(:user))
          end
        end

        context 'in the abuse report view', :aggregate_failures do
          it 'adds pagination' do
            visit admin_abuse_reports_path

            expect(page).to have_selector('.pagination')
            expect(page).to have_selector('.pagination .js-pagination-page', count: (report_count.to_f / AbuseReport.default_per_page).ceil)
          end
        end
      end

      context 'when filtering reports' do
        it 'can be filtered by reported-user', :aggregate_failures do
          visit admin_abuse_reports_path

          page.within '.filter-form' do
            click_button 'User'
            wait_for_requests

            page.within '.dropdown-menu-user' do
              click_link user.name
            end

            wait_for_requests
          end

          expect_report_shown(open_report)
          expect_report_shown(closed_report)
        end
      end

      def expect_report_shown(report)
        page.within(:table_row, { "User" => report.user.name, "Reported by" => report.reporter.name }) do
          expect(page).to have_content(report.user.name)
          expect(page).to have_content(report.reporter.name)
          expect(page).to have_content(report.message)
          expect(page).to have_link(report.user.name, href: user_path(report.user))
        end
      end

      def expect_report_actions_shown(report)
        page.within(:table_row, { "User" => report.user.name, "Reported by" => report.reporter.name }) do
          expect(page).to have_link('Remove user & report')
          expect(page).to have_link('Block user')
          expect(page).to have_link('Remove user')
        end
      end

      def expect_report_actions_not_shown(report)
        page.within(:table_row, { "User" => report.user.name, "Reported by" => report.reporter.name }) do
          expect(page).not_to have_link('Remove user & report')
          expect(page).not_to have_link('Block user')
          expect(page).not_to have_link('Remove user')
        end
      end
    end
  end
end
