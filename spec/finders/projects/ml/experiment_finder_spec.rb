# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ml::ExperimentFinder, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:experiment1) { create(:ml_experiments, project: project) }
  let_it_be(:experiment2) { create(:ml_experiments, project: project) }
  let_it_be(:experiment3) do
    create(:ml_experiments, name: "#{experiment1.name}_1", project: project, updated_at: 1.week.ago)
  end

  let_it_be(:model_experiment) { create(:ml_models, project: project) }
  let_it_be(:experiment4) { model_experiment.default_experiment }
  let_it_be(:other_experiment) { create(:ml_experiments) }
  let_it_be(:project_experiments) { [experiment1, experiment2, experiment3, experiment4] }

  let(:params) { {} }

  subject(:experiments) { described_class.new(project, params).execute.to_a }

  describe 'default params' do
    it 'returns models for project ordered by id, descending' do
      is_expected.to eq([experiment4, experiment3, experiment2, experiment1])
    end

    it 'including the latest version and project', :aggregate_failures do
      expect(experiments[0].association_cached?(:project)).to be(true)
    end

    it 'including the user', :aggregate_failures do
      expect(experiments[0].association_cached?(:user)).to be(true)
    end

    it 'does not return models belonging to a different project' do
      is_expected.not_to include(other_experiment)
    end

    it 'does not return an experiment that belongs to a model' do
      is_expected.not_to include(model_experiment)
    end
  end

  describe 'params with_candidate_count' do
    context 'when with_candidate_count is true' do
      let(:params) { { with_candidate_count: true } }

      it 'does computes candidate_count' do
        expect(experiments[0].candidate_count).to eq(0)
      end
    end

    context 'when with_candidate_count is false' do
      it 'does not compute candidate_count' do
        expect(experiments[0]).not_to respond_to(:candidate_count)
      end
    end
  end

  describe 'sorting' do
    using RSpec::Parameterized::TableSyntax

    where(:test_case, :order_by, :direction, :expected_order) do
      'default params'      | nil          | nil    | [3, 2, 1, 0]
      'ascending order'     | 'id'         | 'ASC'  | [0, 1, 2, 3]
      'descending order'    | 'id'         | 'DSC'  | [3, 2, 1, 0]
      'invalid sort'        | nil          | 'UP'   | [3, 2, 1, 0]
      'invalid order by'    | 'INVALID'    | nil    | [3, 2, 1, 0]
      'order by updated_at' | 'updated_at' | nil    | [3, 1, 0, 2]
    end
    with_them do
      let(:params) { { order_by: order_by, sort: direction } }

      it 'sort correctly' do
        actual_order = project_experiments.values_at(*expected_order)
        expect(experiments).to eq(actual_order)
      end
    end
  end
end
