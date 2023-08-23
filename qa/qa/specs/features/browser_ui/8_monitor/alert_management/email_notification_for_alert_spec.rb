# frozen_string_literal: true

module QA
  RSpec.describe 'Monitor', :orchestrated, :smtp, :requires_admin, product_group: :respond do
    describe 'Alert' do
      shared_examples 'notification on new alert' do
        it 'sends email to user', :aggregate_failures do
          expect { email_subjects }.to eventually_include(alert_email_subject).within(max_duration: 60)
          expect(recipient_email_addresses).to include(user.email)
        end
      end

      let!(:admin_api_client) { Runtime::API::Client.as_admin }

      let!(:user) { create(:user, :hard_delete, api_client: admin_api_client) }

      let(:project) { create(:project, name: 'project-for-alerts', description: 'Project for alerts') }
      let(:alert_title) { Faker::Lorem.word }
      let(:mail_hog_api) { Vendor::MailHog::API.new }
      let(:alert_email_subject) { "#{project.name} | Alert: #{alert_title}" }
      let(:http_payload) { { title: alert_title, description: alert_title } }

      let(:prometheus_payload) do
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
        Flow::Login.sign_in
        project.visit!
        Flow::AlertSettings.go_to_monitor_settings
        Flow::AlertSettings.enable_email_notification
      end

      context 'when user is a maintainer' do
        before do
          project.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
        end

        context(
          'when using HTTP endpoint integration',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/389993'
        ) do
          before do
            send_http_alert
          end

          it_behaves_like 'notification on new alert'
        end

        context(
          'when using Prometheus integration',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/389994'
        ) do
          before do
            send_prometheus_alert
          end

          it_behaves_like 'notification on new alert'
        end
      end

      context 'when user is an owner' do
        before do
          project.add_member(user, Resource::Members::AccessLevel::OWNER)
        end

        context(
          'when using HTTP endpoint integration',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/390145'
        ) do
          before do
            send_http_alert
          end

          it_behaves_like 'notification on new alert'
        end

        context(
          'when using Prometheus integration',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/390144'
        ) do
          before do
            send_prometheus_alert
          end

          it_behaves_like 'notification on new alert'
        end
      end

      private

      def send_http_alert
        Flow::AlertSettings.setup_http_endpoint_integration
        Flow::AlertSettings.send_test_alert(payload: http_payload)
      end

      def send_prometheus_alert
        Flow::AlertSettings.setup_prometheus_integration
        Flow::AlertSettings.send_test_alert(payload: prometheus_payload)
      end

      def mail_hog_messages
        mail_hog_api.fetch_messages
      end

      def email_subjects
        mail_hog_messages.map(&:subject)
      end

      def recipient_email_addresses
        mail_hog_messages.map(&:to)
      end
    end
  end
end
