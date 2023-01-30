# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::RunnerArchitectureType, feature_category: :runner do
  specify { expect(described_class.graphql_name).to eq('RunnerArchitecture') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      name
      download_location
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
