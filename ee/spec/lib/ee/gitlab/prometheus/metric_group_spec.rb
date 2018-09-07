# frozen_string_literal: true

require 'rails_helper'

describe Gitlab::Prometheus::MetricGroup do
  describe '.for_project' do
    let!(:project_metric) { create(:prometheus_metric) }
    let!(:common_metric) { create(:prometheus_metric, :common, group: :aws_elb) }

    subject do
      described_class.for_project(project)
        .map(&:metrics).flatten
        .map(&:id)
    end

    context 'for current project' do
      let(:project) { project_metric.project }

      it 'returns metrics for given project and common ones' do
        is_expected.to contain_exactly(project_metric.id, common_metric.id)
      end
    end

    context 'for other project' do
      let(:project) { create(:project) }

      it 'returns metrics only common ones' do
        is_expected.to contain_exactly(common_metric.id)
      end
    end
  end
end
