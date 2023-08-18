# frozen_string_literal: true

module QA
  RSpec.describe 'Monitor', :smoke, product_group: :respond do
    describe 'Alert settings' do
      shared_examples 'sends test alert' do
        it 'creates new alert' do
          Page::Project::Menu.perform(&:go_to_monitor_alerts)
          Page::Project::Monitor::Alerts::Index.perform do |index|
            expect(index).to have_alert_with_title(alert_title)
          end
        end
      end

      let(:project) { create(:project, name: 'project-for-alerts', description: 'Project for alerts') }
      let(:alert_title) { Faker::Lorem.word }

      before do
        Flow::Login.sign_in
        project.visit!
        Flow::AlertSettings.go_to_monitor_settings
      end

      context(
        'when using HTTP endpoint integration',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/382803'
      ) do
        let(:payload) do
          { title: alert_title, description: alert_title }
        end

        before do
          Flow::AlertSettings.setup_http_endpoint_integration
          Flow::AlertSettings.send_test_alert(payload: payload)
        end

        it_behaves_like 'sends test alert'
      end

      context(
        'when using Prometheus integration',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/385792'
      ) do
        let(:payload) do
          {
            version: '4',
            groupKey: nil,
            status: 'firing',
            receiver: '',
            groupLabels: {},
            commonLabels: {},
            commonAnnotations: {},
            externalURL: '',
            alerts: [
              {
                startsAt: Time.now,
                generatorURL: Faker::Internet.url,
                endsAt: nil,
                status: 'firing',
                labels: { gitlab_environment_name: Faker::Lorem.word },
                annotations:
                  {
                    title: alert_title,
                    gitlab_y_label: 'status'
                  }
              }
            ]
          }
        end

        before do
          Flow::AlertSettings.setup_prometheus_integration
          Flow::AlertSettings.send_test_alert(payload: payload)
        end

        it_behaves_like 'sends test alert'
      end
    end
  end
end
