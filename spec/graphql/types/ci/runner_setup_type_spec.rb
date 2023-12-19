# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::RunnerSetupType, feature_category: :fleet_visibility do
  specify { expect(described_class.graphql_name).to eq('RunnerSetup') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      install_instructions
      register_instructions
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
