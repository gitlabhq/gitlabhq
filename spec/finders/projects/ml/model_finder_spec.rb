# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ml::ModelFinder, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:model1) { create(:ml_models, :with_versions, project: project) }
  let_it_be(:model2) { create(:ml_models, :with_versions, project: project) }
  let_it_be(:model3) { create(:ml_models, name: "#{model1.name}_1", project: project, updated_at: 1.week.ago) }
  let_it_be(:other_model) { create(:ml_models) }
  let_it_be(:project_models) { [model1, model2, model3] }

  let(:params) { {} }

  subject(:models) { described_class.new(project, params).execute.to_a }

  describe 'default params' do
    it 'returns models for project ordered by id' do
      is_expected.to eq([model3, model2, model1])
    end

    it 'including the latest version and project', :aggregate_failures do
      expect(models[0].association_cached?(:latest_version)).to be(true)
      expect(models[0].association_cached?(:project)).to be(true)
      expect(models[1].association_cached?(:latest_version)).to be(true)
      expect(models[1].association_cached?(:project)).to be(true)
    end

    it 'does not return models belonging to a different project' do
      is_expected.not_to include(other_model)
    end

    it 'includes version count' do
      expect(models[0].version_count).to be(models[0].versions.count)
    end
  end

  context 'when name is passed' do
    let(:params) { { name: model1.name } }

    it 'searches by name' do
      is_expected.to match_array([model1, model3])
    end
  end

  describe 'sorting' do
    using RSpec::Parameterized::TableSyntax

    where(:test_case, :order_by, :direction, :expected_order) do
      'default params'     | nil       | nil    | [2, 1, 0]
      'ascending order'    | 'id'      | 'ASC'  | [0, 1, 2]
      'by column'          | 'name'    | 'ASC'  | [0, 2, 1]
      'invalid sort'       | nil       | 'UP'   | [2, 1, 0]
      'invalid order by'   | 'INVALID' | nil    | [2, 1, 0]
      'order by updated_at' | 'updated_at' | nil | [1, 0, 2]
    end
    with_them do
      let(:params) { { order_by: order_by, sort: direction } }

      it { expect(subject).to eq(project_models.values_at(*expected_order)) }
    end
  end
end
