# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Config::GroupType do
  specify { expect(described_class.graphql_name).to eq('CiConfigGroup') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      name
      jobs
      size
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
