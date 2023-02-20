# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ml::CandidateFinder, feature_category: :mlops do
  let_it_be(:experiment) { create(:ml_experiments, user: nil) }

  let_it_be(:candidates) do
    %w[c a da b].zip([3, 2, 4, 1]).map do |name, auc|
      make_candidate_and_metric(name, auc, experiment)
    end
  end

  let_it_be(:another_candidate) { create(:ml_candidates) }
  let_it_be(:first_candidate) { candidates.first }

  let(:finder) { described_class.new(experiment, params) }
  let(:page) { 1 }
  let(:default_params) { { page: page } }
  let(:params) { default_params }

  subject { finder.execute }

  describe '.execute' do
    describe 'by name' do
      context 'when params has no name' do
        it 'fetches all candidates in the experiment' do
          expect(subject).to match_array(candidates)
        end

        it 'does not fetch candidate not in experiment' do
          expect(subject).not_to include(another_candidate)
        end
      end

      context 'when name is included in params' do
        let(:params) { { name: 'a' } }

        it 'fetches the correct candidates' do
          expect(subject).to match_array(candidates.values_at(2, 1))
        end
      end
    end

    describe 'sorting' do
      using RSpec::Parameterized::TableSyntax

      where(:test_case, :order_by, :order_by_type, :direction, :expected_order) do
        'default params' | nil | nil |  nil | [3, 2, 1, 0]
        'ascending order' | nil | nil | 'ASC' | [0, 1, 2, 3]
        'column is passed' | 'name' | 'column' | 'ASC' | [1, 3, 0, 2]
        'column is a metric' | 'auc' | 'metric' | nil | [2, 0, 1, 3]
        'invalid sort' | nil | nil | 'INVALID' | [3, 2, 1, 0]
        'invalid order by' | 'INVALID' | 'column' | 'desc' | [3, 2, 1, 0]
        'invalid order by metric' | nil | 'metric' | 'desc' | []
      end
      with_them do
        let(:params) { { order_by: order_by, order_by_type: order_by_type, sort: direction } }

        it { expect(subject).to eq(candidates.values_at(*expected_order)) }
      end
    end

    context 'when name and sort by metric is passed' do
      let(:params) { { order_by: 'auc', order_by_type: 'metric', sort: 'DESC', name: 'a' } }

      it { expect(subject).to eq(candidates.values_at(2, 1)) }
    end
  end

  private

  def make_candidate_and_metric(name, auc_value, experiment)
    create(:ml_candidates, name: name, experiment: experiment, user: nil).tap do |c|
      create(:ml_candidate_metrics, name: 'auc', candidate_id: c.id, value: 10)
      create(:ml_candidate_metrics, name: 'auc', candidate_id: c.id, value: auc_value)
    end
  end
end
