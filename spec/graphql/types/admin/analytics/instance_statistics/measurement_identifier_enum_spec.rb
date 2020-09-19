# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MeasurementIdentifier'] do
  specify { expect(described_class.graphql_name).to eq('MeasurementIdentifier') }

  it 'exposes all the existing identifier values' do
    identifiers = Analytics::InstanceStatistics::Measurement.identifiers.keys.map(&:upcase)

    expect(described_class.values.keys).to match_array(identifiers)
  end
end
