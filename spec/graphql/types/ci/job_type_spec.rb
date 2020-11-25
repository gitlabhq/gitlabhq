# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::JobType do
  specify { expect(described_class.graphql_name).to eq('CiJob') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      pipeline
      name
      needs
      detailedStatus
      scheduledAt
      artifacts
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
