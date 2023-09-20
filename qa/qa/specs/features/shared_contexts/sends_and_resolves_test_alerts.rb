# frozen_string_literal: true

module QA
  RSpec.shared_context 'sends and resolves test alerts' do
    let(:project) { create(:project, name: 'project-for-alerts', description: 'Project for alerts') }
    let(:resolve_title) { Faker::Lorem.sentence }
    let(:unresolve_title) { Faker::Lorem.sentence }
    let(:http) { true }

    let(:payload_to_be_resolved) do
      payload(resolve_title, http)
    end

    let(:unresolved_payload) do
      payload(unresolve_title, http)
    end

    before do
      http ? Flow::AlertSettings.setup_http_endpoint_integration : Flow::AlertSettings.setup_prometheus_integration

      [payload_to_be_resolved, unresolved_payload].each do |payload|
        Flow::AlertSettings.send_test_alert(payload: payload)
      end

      mark_as_resolved(payload_to_be_resolved, http)
      Flow::AlertSettings.send_test_alert(payload: payload_to_be_resolved)
    end

    private

    def mark_as_resolved(payload, http)
      sleep 3 # To ensure create and end time are different

      if http
        payload[:end_time] = Time.now
      else
        payload[:alerts][0][:status] = 'resolved'
        payload[:alerts][0][:endsAt] = Time.now
      end
    end

    def payload(title, http)
      if http
        { title: title, description: title }
      else
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
              status: nil,
              labels: { gitlab_environment_name: Faker::Lorem.word },
              annotations: { title: title }
            }
          ]
        }
      end
    end
  end
end
