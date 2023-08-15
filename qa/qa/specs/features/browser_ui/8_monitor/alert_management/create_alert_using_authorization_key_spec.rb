# frozen_string_literal: true

module QA
  RSpec.describe 'Monitor', :smoke, product_group: :respond do
    describe 'Alert settings' do
      shared_examples 'sends test alert using authorization key' do |type|
        it 'creates new alert', :aggregate_failures do
          response = RestClient.post(
            credentials[:url],
            payload.to_json,
            { 'Content-Type': 'application/json', Authorization: "Bearer #{credentials[:auth_key]}" }
          )

          # With HTTP type, a successful request returns 200 and a JSON with the alert's title
          # With Prometheus type, a successful request returns 201
          if type == 'http'
            expect(response.code).to eq 200
            expect(JSON.parse(response).first['title']).to eq alert_title
          else
            expect(response.code).to eq 201
          end

          Page::Project::Menu.perform(&:go_to_monitor_alerts)
          Page::Project::Monitor::Alerts::Index.perform do |index|
            expect { index.has_alert_with_title?(alert_title) }
              .to eventually_be_truthy.within(max_duration: 60, reload_page: index)
          end
        end
      end

      let(:project) { create(:project, name: 'project-for-alerts', description: 'Project for alerts') }
      let(:alert_title) { Faker::Lorem.word }
      let(:credentials) do
        Flow::AlertSettings.integration_credentials
      end

      before do
        Flow::Login.sign_in
        project.visit!
        Flow::AlertSettings.go_to_monitor_settings
      end

      context(
        'when using HTTP endpoint integration',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/386734'
      ) do
        let(:payload) do
          { title: alert_title, description: alert_title }
        end

        before do
          Flow::AlertSettings.setup_http_endpoint_integration
        end

        it_behaves_like 'sends test alert using authorization key', 'http'
      end

      context(
        'when using Prometheus integration',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/386735'
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
        end

        it_behaves_like 'sends test alert using authorization key'
      end
    end
  end
end
