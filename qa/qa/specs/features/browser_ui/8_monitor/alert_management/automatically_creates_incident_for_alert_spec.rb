# frozen_string_literal: true

module QA
  RSpec.describe 'Monitor', product_group: :respond do
    describe 'Alert' do
      shared_examples 'new alert' do
        it 'automatically creates new incident' do
          Page::Project::Menu.perform(&:go_to_monitor_incidents)
          Page::Project::Monitor::Incidents::Index.perform do |index|
            expect(index).to have_incident
          end
        end
      end

      let(:project) { create(:project, name: 'project-for-alerts', description: 'Project for alerts') }

      before do
        Flow::Login.sign_in
        project.visit!
        Flow::AlertSettings.go_to_monitor_settings
        Flow::AlertSettings.enable_create_incident
      end

      context(
        'when using HTTP endpoint integration',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/388469'
      ) do
        before do
          Flow::AlertSettings.setup_http_endpoint_integration
          Flow::AlertSettings.send_test_alert
        end

        it_behaves_like 'new alert'
      end

      context(
        'when using Prometheus integration',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/390123'
      ) do
        before do
          Flow::AlertSettings.setup_prometheus_integration
          Flow::AlertSettings.send_test_alert(integration_type: 'prometheus')
        end

        it_behaves_like 'new alert'
      end
    end
  end
end
