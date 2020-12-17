# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Config::StageType do
  specify { expect(described_class.graphql_name).to eq('CiConfigStage') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      name
      groups
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
