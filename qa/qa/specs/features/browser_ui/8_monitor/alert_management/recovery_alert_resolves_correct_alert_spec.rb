# frozen_string_literal: true

module QA
  RSpec.describe 'Monitor', product_group: :respond do
    describe 'Recovery alert' do
      shared_examples 'triggers recovery alert' do
        it 'only resolves the correct alert', :aggregate_failures do
          Page::Project::Menu.perform(&:go_to_monitor_alerts)
          Page::Project::Monitor::Alerts::Index.perform do |index|
            # Open tab is displayed by default
            expect(index).to have_alert_with_title(unresolve_title)
            expect(index).to have_no_alert_with_title(resolve_title)

            index.go_to_tab('Resolved')
            expect(index).to have_alert_with_title(resolve_title)
            expect(index).to have_no_alert_with_title(unresolve_title)
          end
        end
      end

      before do
        Flow::Login.sign_in
        project.visit!
        Flow::AlertSettings.go_to_monitor_settings
      end

      context(
        'when using HTTP endpoint integration',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/393589',
        quarantine: {
          only: { pipeline: :nightly },
          type: :bug,
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/395512'
        }
      ) do
        include_context 'sends and resolves test alerts'

        it_behaves_like 'triggers recovery alert'
      end

      context(
        'when using Prometheus integration',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/393590',
        quarantine: {
          type: :flaky,
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/413220'
        }
      ) do
        include_context 'sends and resolves test alerts'

        let(:http) { false }

        it_behaves_like 'triggers recovery alert'
      end
    end
  end
end
