# frozen_string_literal: true

require 'spec_helper'

describe Projects::Prometheus::Alerts::NotifyService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:service) { described_class.new(project, user, payload) }

  context 'with valid payload' do
    let(:alert_firing) { create(:prometheus_alert, project: project) }
    let(:alert_resolved) { create(:prometheus_alert, project: project) }
    let(:notification_service) { spy }
    let(:payload) { payload_for(firing: [alert_firing], resolved: [alert_resolved]) }
    let(:payload_alert_firing) { payload['alerts'].first }

    before do
      allow(NotificationService).to receive(:new).and_return(notification_service)
    end

    it 'sends a notification for firing alerts only' do
      expect(notification_service)
        .to receive_message_chain(:async, :prometheus_alerts_fired)
        .with(project, [payload_alert_firing])

      expect(service.execute).to eq(true)
    end
  end

  context 'with invalid payload' do
    let(:payload) { {} }

    it 'returns false without `version`' do
      expect(service.execute).to eq(false)
    end

    it 'returns false if `version` is not 4' do
      payload['version'] = '5'

      expect(service.execute).to eq(false)
    end
  end

  private

  def payload_for(firing: [], resolved: [])
    status = firing.any? ? 'firing' : 'resolved'
    alerts = firing + resolved
    alert_name = alerts.first.title
    prometheus_metric_id = alerts.first.prometheus_metric_id.to_s

    alerts_map = \
      firing.map { |alert| map_alert_payload('firing', alert) } +
      resolved.map { |alert| map_alert_payload('resolved', alert) }

    # See https://prometheus.io/docs/alerting/configuration/#%3Cwebhook_config%3E
    {
      'version' => '4',
      'receiver' => 'gitlab',
      'status' => status,
      'alerts' => alerts_map,
      'groupLabels' => {
        'alertname' => alert_name
      },
      'commonLabels' => {
        'alertname' => alert_name,
        'gitlab' => 'hook',
        'gitlab_alert_id' => prometheus_metric_id
      },
      'commonAnnotations' => {},
      'externalURL' => '',
      'groupKey' => "{}:{alertname=\'#{alert_name}\'}"
    }
  end

  def map_alert_payload(status, alert)
    {
      'status' => status,
      'labels' => {
        'alertname' => alert.title,
        'gitlab' => 'hook',
        'gitlab_alert_id' => alert.prometheus_metric_id.to_s
      },
      'annotations' => {},
      'startsAt' => '2018-09-24T08:57:31.095725221Z',
      'endsAt' => '0001-01-01T00:00:00Z',
      'generatorURL' => 'http://prometheus-prometheus-server-URL'
    }
  end
end
