# frozen_string_literal: true

module QA
  RSpec.describe 'Analytics', product_group: :analytics_instrumentation do
    describe 'Service ping disabled', :orchestrated, :service_ping_disabled, :requires_admin do
      context 'when disabled from gitlab.yml config' do
        before do
          Flow::Login.sign_in_as_admin

          Page::Main::Menu.perform(&:go_to_admin_area)
          Page::Admin::Menu.perform(&:go_to_metrics_and_profiling_settings)
        end

        it(
          'has service ping toggle is disabled',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348340'
        ) do
          Page::Admin::Settings::MetricsAndProfiling.perform do |settings|
            settings.expand_usage_statistics do |usage_statistics|
              expect(usage_statistics).to have_disabled_usage_data_checkbox
            end
          end
        end
      end
    end
  end
end
