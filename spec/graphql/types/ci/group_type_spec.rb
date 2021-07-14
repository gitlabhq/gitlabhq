# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::GroupType do
  specify { expect(described_class.graphql_name).to eq('CiGroup') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      name
      size
      jobs
      detailedStatus
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
