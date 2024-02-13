# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ml::ModelVersionFinder, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:model) { create(:ml_models, project: project) }
  let_it_be(:model_version_2_0_1) { create(:ml_model_versions, model: model, version: '2.0.1') }
  let_it_be(:model_version_3_0_0) { create(:ml_model_versions, model: model, version: '3.0.0') }
  let_it_be(:model_version_1_0_1) { create(:ml_model_versions, model: model, version: '1.0.1') }
  let_it_be(:other_model_version) { create(:ml_model_versions) }
  let_it_be(:model_versions) { [model_version_2_0_1, model_version_3_0_0, model_version_1_0_1] }

  let(:params) { {} }

  subject(:loaded_versions) { described_class.new(model, params).execute.to_a }

  describe 'default params' do
    it 'returns models for project ordered by id desc' do
      is_expected.to contain_exactly(model_version_1_0_1, model_version_3_0_0, model_version_2_0_1)
    end

    it 'including the latest version and project', :aggregate_failures do
      expect(loaded_versions[0].association_cached?(:project)).to be(true)
      expect(loaded_versions[0].association_cached?(:model)).to be(true)
      expect(loaded_versions[1].association_cached?(:project)).to be(true)
      expect(loaded_versions[1].association_cached?(:model)).to be(true)
    end
  end

  context 'when version is passed' do
    let(:params) { { version: '2.0' } }

    it 'searches by name' do
      is_expected.to contain_exactly(model_version_2_0_1)
    end
  end

  describe 'sorting' do
    using RSpec::Parameterized::TableSyntax

    where(:test_case, :order_by, :direction, :expected_order) do
      'default params'      | nil          | nil    | [2, 1, 0]
      'ascending order'     | 'id'         | 'ASC'  | [0, 1, 2]
      'by version'          | 'version'    | 'ASC'  | [2, 0, 1]
      'by version desc'     | 'version'    | 'DESC' | [1, 0, 2]
      'invalid sort'        | nil          | 'UP'   | [2, 1, 0]
      'invalid order by'    | 'INVALID'    | nil    | [2, 1, 0]
      'order by updated_at' | 'created_at' | nil    | [2, 1, 0]
    end
    with_them do
      let(:params) { { order_by: order_by, sort: direction } }

      it { expect(loaded_versions).to eq(model_versions.values_at(*expected_order)) }
    end
  end
end
