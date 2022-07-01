# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::RunnerUpgradeStatusTypeEnum do
  specify { expect(described_class.graphql_name).to eq('CiRunnerUpgradeStatusType') }

  it 'exposes all upgrade status values except not_processed' do
    expect(described_class.values.keys).to match_array(
      Ci::RunnerVersion.statuses.keys
        .reject { |k| k == 'not_processed' }
        .map { |k| k.upcase }
        .map { |v| v == 'INVALID_VERSION' ? 'INVALID' : v }
    )
  end
end
