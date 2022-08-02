# frozen_string_literal: true

module QA
  RSpec.describe 'Analytics' do
    describe 'Performance bar display', :requires_admin, :skip_live_env do
      context 'when logged in as an admin user' do
        # performance metrics: pg, gitaly, redis, rugged (feature flagged), total (not always provided)
        let(:minimum_metrics_count) { 3 }

        before do
          Flow::Login.sign_in_as_admin
          Page::Main::Menu.perform(&:go_to_admin_area)
          Page::Admin::Menu.perform(&:go_to_metrics_and_profiling_settings)

          Page::Admin::Settings::MetricsAndProfiling.perform do |setting|
            setting.expand_performance_bar do |page|
              page.enable_performance_bar
              page.save_settings
            end
          end
        end

        it(
          'shows results for the original request and AJAX requests',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348030'
        ) do
          # Issue pages always make AJAX requests
          Resource::Issue.fabricate_via_browser_ui! do |issue|
            issue.title = 'Performance bar test'
          end

          Page::Layout::PerformanceBar.perform do |bar_component|
            expect(bar_component).to have_performance_bar
            expect(bar_component).to have_detailed_metrics(minimum_metrics_count)
            expect(bar_component).to have_request_for('realtime_changes') # Always requested on issue pages
          end
        end
      end
    end
  end
end
