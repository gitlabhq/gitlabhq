# frozen_string_literal: true

module QA
  context 'Performance bar' do
    context 'when logged in as an admin user' do
      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_admin_credentials)
        Page::Main::Menu.perform(&:click_admin_area)
        Page::Admin::Menu.perform(&:go_to_metrics_and_profiling_settings)

        Page::Admin::Settings::MetricsAndProfiling.perform do |setting|
          setting.expand_performance_bar do |page|
            page.enable_performance_bar
            page.save_settings
          end
        end
      end

      it 'shows results for the original request and AJAX requests' do
        # Issue pages always make AJAX requests
        Resource::Issue.fabricate! do |issue|
          issue.title = 'Performance bar test'
        end

        Page::Layout::PerformanceBar.perform do |page|
          expect(page).to have_performance_bar
          expect(page).to have_detailed_metrics
          expect(page).to have_request_for('realtime_changes') # Always requested on issue pages
        end
      end
    end
  end
end
