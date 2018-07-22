require 'spec_helper'

describe PrometheusAlert do
  let(:metric) { create(:prometheus_metric) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:environment) }
  end

  describe '#full_query' do
    it 'returns the concatenated query' do
      subject.operator = "gt"
      subject.threshold = 1
      subject.prometheus_metric_id = metric.id

      expect(subject.full_query).to eq("#{metric.query} > 1.0")
    end
  end

  describe '#to_param' do
    it 'returns the params of the prometheus alert' do
      subject.operator = "gt"
      subject.threshold = 1
      subject.prometheus_metric_id = metric.id

      alert_params = {
        "alert" => metric.title,
        "expr" => "#{metric.query} > 1.0",
        "for" => "5m",
        "labels" => {
          "gitlab" => "hook",
          "gitlab_alert_id" => metric.id
        }
      }

      expect(subject.to_param).to eq(alert_params)
    end
  end
end
