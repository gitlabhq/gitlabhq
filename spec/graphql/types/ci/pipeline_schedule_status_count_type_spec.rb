# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineScheduleStatusCountType, feature_category: :continuous_integration do
  it 'has the expected fields' do
    expected_fields = %w[active inactive total]
    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'active field' do
    subject(:active_type) { described_class.fields['active'] }

    it { is_expected.to have_graphql_type(GraphQL::Types::Int.to_non_null_type) }
    it { expect(active_type.description).to eq('Number of active pipeline schedules.') }
  end

  describe 'inactive field' do
    subject(:inactive_type) { described_class.fields['inactive'] }

    it { is_expected.to have_graphql_type(GraphQL::Types::Int.to_non_null_type) }
    it { expect(inactive_type.description).to eq('Number of inactive pipeline schedules.') }
  end

  describe 'total field' do
    subject(:total_type) { described_class.fields['total'] }

    it { is_expected.to have_graphql_type(GraphQL::Types::Int.to_non_null_type) }
    it { expect(total_type.description).to eq('Total number of pipeline schedules.') }
  end
end
