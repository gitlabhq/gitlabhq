# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Config::JobType do
  specify { expect(described_class.graphql_name).to eq('CiConfigJob') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      name
      group_name
      stage
      needs
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
