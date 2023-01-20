# frozen_string_literal: true

module QA
  RSpec.describe 'Monitor', product_group: :respond do
    describe 'Alert' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-for-alerts'
          project.description = 'Project for alerts'
        end
      end

      before do
        Flow::Login.sign_in
        project.visit!
        Flow::AlertSettings.go_to_monitor_settings
        Flow::AlertSettings.enable_create_incident
        Flow::AlertSettings.setup_http_endpoint_integration
        Flow::AlertSettings.send_test_alert
      end

      it(
        'can automatically create incident',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/388469'
      ) do
        Page::Project::Menu.perform(&:go_to_monitor_incidents)
        Page::Project::Monitor::Incidents::Index.perform do |index|
          expect(index).to have_incident
        end
      end
    end
  end
end
