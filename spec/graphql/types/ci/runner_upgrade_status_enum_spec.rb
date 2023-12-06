# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::RunnerUpgradeStatusEnum, feature_category: :fleet_visibility do
  let(:model_only_enum_values) { %w[not_processed] }
  let(:expected_graphql_source_values) do
    Ci::RunnerVersion.statuses.keys - model_only_enum_values
  end

  specify { expect(described_class.graphql_name).to eq('CiRunnerUpgradeStatus') }

  it 'exposes all upgrade status values except not_processed' do
    expect(described_class.values.keys).to match_array(
      expected_graphql_source_values
        .map(&:upcase)
        .map { |v| v == 'INVALID_VERSION' ? 'INVALID' : v }
        .map { |v| v == 'UNAVAILABLE' ? 'NOT_AVAILABLE' : v }
    )
  end

  it 'exposes all upgrade status values except enum-only values' do
    expect(described_class.values.values.map(&:value).map(&:to_s)).to match_array(expected_graphql_source_values)
  end
end
