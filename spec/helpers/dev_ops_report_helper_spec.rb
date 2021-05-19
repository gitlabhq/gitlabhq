# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DevOpsReportHelper do
  subject { DevOpsReport::MetricPresenter.new(metric) }

  let(:metric) { build(:dev_ops_report_metric, created_at: DateTime.new(2021, 4, 3, 2, 1, 0) ) }

  describe '#devops_score_metrics' do
    let(:devops_score_metrics) { helper.devops_score_metrics(subject) }

    it { expect(devops_score_metrics[:averageScore]).to eq({ scoreLevel: { icon: "status-alert", label: "Moderate", variant: "warning" }, value: "55.9" } ) }

    it { expect(devops_score_metrics[:cards].first).to eq({ leadInstance: "9.3", score: "13.3", scoreLevel: { label: "Low", variant: "muted" }, title: "Issues created per active user", usage: "1.2" } ) }
    it { expect(devops_score_metrics[:cards].second).to eq({ leadInstance: "30.3", score: "92.7", scoreLevel: { label: "High", variant: "success" }, title: "Comments created per active user", usage: "28.1" } ) }
    it { expect(devops_score_metrics[:cards].fourth).to eq({ leadInstance: "5.2", score: "62.4", scoreLevel: { label: "Moderate", variant: "neutral" }, title: "Boards created per active user", usage: "3.3" } ) }

    it { expect(devops_score_metrics[:createdAt]).to eq("2021-04-03 02:01") }

    describe 'with low average score' do
      let(:low_metric) { double(average_percentage_score: 2, cards: subject.cards, created_at: subject.created_at) }
      let(:devops_score_metrics) { helper.devops_score_metrics(low_metric) }

      it { expect(devops_score_metrics[:averageScore]).to eq({ scoreLevel: { icon: "status-failed", label: "Low", variant: "danger" }, value: "2.0" } ) }
    end

    describe 'with high average score' do
      let(:high_metric) { double(average_percentage_score: 82, cards: subject.cards, created_at: subject.created_at) }
      let(:devops_score_metrics) { helper.devops_score_metrics(high_metric) }

      it { expect(devops_score_metrics[:averageScore]).to eq({ scoreLevel: { icon: "status_success_solid", label: "High", variant: "success" }, value: "82.0" } ) }
    end

    describe 'with blank metrics' do
      let(:devops_score_metrics) { helper.devops_score_metrics({}) }

      it { expect(devops_score_metrics).to eq({}) }
    end
  end
end
