# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ml::MetricHistoryFinder, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:experiment) { create(:ml_experiments, project: project) }
  let_it_be(:candidate) { create(:ml_candidates, experiment: experiment, project: project) }

  let_it_be(:metrics) do
    Array.new(3) do |step|
      create(:ml_candidate_metrics,
        candidate: candidate,
        name: 'loss',
        value: 1.0 / (step + 1),
        step: step,
        tracked_at: (Time.now.to_i * 1000) + step)
    end
  end

  let_it_be(:other_metric) do
    create(:ml_candidate_metrics, candidate: candidate, name: 'accuracy', value: 0.9, step: 0)
  end

  subject(:result) { described_class.new(candidate, metric_key).execute }

  describe '#execute' do
    let(:metric_key) { 'loss' }

    it 'returns metrics for the given candidate and metric key' do
      expect(result).to eq(metrics)
    end

    it 'orders by step ascending' do
      steps = result.pluck(:step)
      expect(steps).to eq([0, 1, 2])
    end

    it 'does not include metrics with a different name' do
      expect(result).not_to include(other_metric)
    end

    context 'when metric key does not exist' do
      let(:metric_key) { 'nonexistent' }

      it 'returns empty relation' do
        expect(result).to be_empty
      end
    end
  end
end
