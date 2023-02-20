# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::RunnerPlatformType, feature_category: :runner_fleet do
  specify { expect(described_class.graphql_name).to eq('RunnerPlatform') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      name
      human_readable_name
      architectures
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
