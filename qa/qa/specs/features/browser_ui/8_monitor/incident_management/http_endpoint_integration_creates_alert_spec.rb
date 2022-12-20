# frozen_string_literal: true

module QA
  RSpec.describe 'Monitor', product_group: :respond do
    describe 'Http endpoint integration' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-for-alerts'
          project.description = 'Project for alerts'
        end
      end

      let(:random_word) { Faker::Lorem.word }

      let(:payload) do
        { title: random_word, description: random_word }
      end

      before do
        Flow::Login.sign_in
        project.visit!
        Flow::AlertSettings.setup_http_endpoint_and_send_alert(payload: payload)
      end

      it(
        'can send test alert that creates new alert',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/382803'
      ) do
        Page::Project::Menu.perform(&:go_to_monitor_alerts)
        Page::Project::Monitor::Alerts::Index.perform do |alerts|
          expect(alerts).to have_alert_with_title(random_word)
        end
      end
    end
  end
end
