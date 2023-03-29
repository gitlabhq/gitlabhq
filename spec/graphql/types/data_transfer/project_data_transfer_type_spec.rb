# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ProjectDataTransfer'], feature_category: :source_code_management do
  include GraphqlHelpers

  it 'includes the specific fields' do
    expect(described_class).to have_graphql_fields(
      :total_egress, :egress_nodes)
  end

  describe '#total_egress' do
    let_it_be(:project) { create(:project) }
    let(:from) { Date.new(2022, 1, 1) }
    let(:to) { Date.new(2023, 1, 1) }
    let(:finder_result) { 40_000_000 }

    it 'returns mock data' do
      expect(resolve_field(:total_egress, { from: from, to: to }, extras: { parent: project },
        arg_style: :internal)).to eq(finder_result)
    end

    context 'when data_transfer_monitoring_mock_data is disabled' do
      let(:relation) { instance_double(ActiveRecord::Relation) }

      before do
        allow(relation).to receive(:sum).and_return(10)
        stub_feature_flags(data_transfer_monitoring_mock_data: false)
      end

      it 'calls sum on active record relation' do
        expect(resolve_field(:total_egress, { egress_nodes: relation }, extras: { parent: project },
          arg_style: :internal)).to eq(10)
      end
    end
  end
end
