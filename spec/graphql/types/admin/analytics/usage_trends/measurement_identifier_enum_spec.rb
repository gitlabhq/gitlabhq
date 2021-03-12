# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MeasurementIdentifier'] do
  specify { expect(described_class.graphql_name).to eq('MeasurementIdentifier') }

  it 'exposes all the existing identifier values' do
    ee_only_identifiers = %w[billable_users]
    identifiers = Analytics::UsageTrends::Measurement.identifiers.keys.reject do |x|
      ee_only_identifiers.include?(x)
    end.map(&:upcase)

    expect(described_class.values.keys).to match_array(identifiers)
  end
end
