require 'spec_helper'

describe PrometheusAlertEntity do
  let(:user) { create(:user) }
  let(:prometheus_alert) { create(:prometheus_alert) }
  let(:request) { double('prometheus_alert', current_user: user) }
  let(:entity) { described_class.new(prometheus_alert, request: request) }

  subject { entity.as_json }

  context 'when user can read prometheus alerts' do
    before do
      prometheus_alert.project.add_master(user)
      stub_licensed_features(prometheus_alerts: true)
    end

    it 'exposes prometheus_alert attributes' do
      expect(subject).to include(:id, :title, :query, :operator, :threshold)
    end

    it 'exposes alert_path' do
      expect(subject).to include(:alert_path)
    end
  end
end
