# frozen_string_literal: true

module QA
  RSpec.describe 'Monitor', :smoke, product_group: :respond, feature_flag: {
    name: :hide_incident_management_features
  } do
    describe 'Alert Management' do
      let(:project) { create(:project, name: 'project-for-alerts', description: 'Project for alerts') }
      let(:alert_title) { Faker::Lorem.word }
      let(:resolve_title) { "resolve-#{Faker::Lorem.word}" }
      let(:unresolve_title) { "unresolve-#{Faker::Lorem.word}" }
      let(:enable_incidents) { false }

      before do
        Flow::Login.sign_in
        project.visit!
        Flow::AlertSettings.go_to_monitor_settings
        Flow::AlertSettings.enable_create_incident if enable_incidents
      end

      shared_context 'with enabled incidents' do
        let(:enable_incidents) { true }
      end

      shared_context 'with HTTP integration setup' do
        let(:http) { true }
        let(:payload) do
          { title: alert_title, description: alert_title }
        end

        before do
          Flow::AlertSettings.setup_http_endpoint_integration
        end
      end

      shared_context 'with Prometheus integration setup' do
        let(:http) { false }
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
                annotations: {
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
      end

      shared_examples 'creates alerts via UI' do |testcase|
        it 'creates new alert', testcase: testcase do
          Flow::AlertSettings.send_test_alert(payload: payload)

          Page::Project::Menu.perform(&:go_to_monitor_alerts)
          Page::Project::Monitor::Alerts::Index.perform do |index|
            expect(index).to have_alert_with_title(alert_title)
          end
        end
      end

      shared_examples 'creates alerts using authorization key' do |testcase|
        it 'creates new alert', :aggregate_failures, testcase: testcase do
          credentials = Flow::AlertSettings.integration_credentials

          response = RestClient.post(
            credentials[:url],
            payload.to_json,
            { 'Content-Type': 'application/json', Authorization: "Bearer #{credentials[:auth_key]}" }
          )

          # With HTTP type, a successful request returns 200 and a JSON with the alert's title
          # With Prometheus type, a successful request returns 201
          if http
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

      shared_examples 'creates incident from alert' do |testcase|
        include_context 'with enabled incidents'
        it 'automatically creates new incident', testcase: testcase do
          integration_type = if http
                               'http'
                             else
                               'prometheus'
                             end

          Page::Project::Settings::Monitor.perform(&:expand_alerts)
          Flow::AlertSettings.send_test_alert(integration_type: integration_type)

          unless Runtime::Feature.enabled?(:hide_incident_management_features)
            Page::Project::Menu.perform(&:go_to_monitor_incidents)
            Page::Project::Monitor::Incidents::Index.perform do |index|
              expect(index).to have_incident
            end
          end
        end
      end

      shared_examples 'resolves alerts correctly' do |testcase, quarantine|
        include_context 'sends and resolves test alerts'
        it 'only resolves the correct alert', :aggregate_failures, testcase: testcase, quarantine: quarantine do
          # Send two alerts, then resolve one
          Page::Project::Menu.perform(&:go_to_monitor_alerts)
          Page::Project::Monitor::Alerts::Index.perform do |index|
            # Verify open tab
            expect(index).to have_alert_with_title(unresolve_title)
            expect(index).to have_no_alert_with_title(resolve_title)
            # Verify resolved tab
            index.go_to_tab('Resolved')
            expect(index).to have_alert_with_title(resolve_title)
            expect(index).to have_no_alert_with_title(unresolve_title)
          end
        end
      end

      context 'when HTTP endpoint integration' do
        include_context 'with HTTP integration setup'

        it_behaves_like 'creates alerts via UI',
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/382803'

        it_behaves_like 'creates alerts using authorization key',
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/386734'

        it_behaves_like 'creates incident from alert',
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/388469'

        it_behaves_like 'resolves alerts correctly',
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/393589',
          {
            only: { condition: -> { ENV['QA_RUN_TYPE'] == 'e2e-test-on-omnibus-ce' } },
            type: :bug,
            issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/395512'
          }
      end

      context 'when Prometheus integration' do
        include_context 'with Prometheus integration setup'

        it_behaves_like 'creates alerts via UI',
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/385792'

        it_behaves_like 'creates alerts using authorization key',
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/386735'

        it_behaves_like 'creates incident from alert',
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/390123'

        it_behaves_like 'resolves alerts correctly',
          'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/393590',
          {
            type: :flaky,
            issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/413220'
          }
      end
    end
  end
end
