# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::RunnerUpgradeStatusTypeEnum do
  specify { expect(described_class.graphql_name).to eq('CiRunnerUpgradeStatusType') }

  it 'exposes all upgrade status values' do
    expect(described_class.values.keys).to eq(
      ::Gitlab::Ci::RunnerUpgradeCheck::STATUSES.map { |sym, _| sym.to_s.upcase }
    )
  end
end
