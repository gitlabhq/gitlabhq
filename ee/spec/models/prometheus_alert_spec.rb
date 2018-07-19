require 'spec_helper'

describe PrometheusAlert do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:environment) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe '#full_query' do
    it 'returns the concatenated query' do
      subject.name = "bar"
      subject.query = "foo"
      subject.operator = "gt"
      subject.threshold = 1
      subject.prometheus_metric_id = 1

      expect(subject.full_query).to eq("foo > 1.0")
    end
  end

  describe '#to_param' do
    it 'returns the params of the prometheus alert' do
      subject.name = "bar"
      subject.query = "foo"
      subject.operator = "gt"
      subject.threshold = 1
      subject.prometheus_metric_id = 1

      alert_params = {
        "alert" => "bar",
        "expr" => "foo > 1.0",
        "for" => "5m",
        "labels" => {
          "gitlab" => "hook",
          "gitlab_alert_id" => 1
        }
      }

      expect(subject.to_param).to eq(alert_params)
    end
  end
end
