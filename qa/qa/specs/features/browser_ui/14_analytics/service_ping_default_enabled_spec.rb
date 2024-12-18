# frozen_string_literal: true

module QA
  RSpec.describe 'Analytics' do
    describe 'Service ping default enabled', product_group: :analytics_instrumentation do
      context 'when using default enabled from gitlab.yml config', :requires_admin do
        before do
          Flow::Login.sign_in_as_admin

          Page::Main::Menu.perform(&:go_to_admin_area)
          Page::Admin::Menu.perform(&:go_to_metrics_and_profiling_settings)
        end

        it(
          'has service ping toggle enabled',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348335'
        ) do
          Page::Admin::Settings::MetricsAndProfiling.perform do |setting|
            setting.expand_usage_statistics do |page|
              expect(page).not_to have_disabled_usage_data_checkbox
            end
          end
        end
      end
    end
  end
end
