# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::IssuableSeverityEnum, feature_category: :incident_management do
  specify { expect(described_class.graphql_name).to eq('IssuableSeverity') }

  it 'exposes all the existing issuable severity values' do
    expect(described_class.values.keys).to match_array(%w[UNKNOWN LOW MEDIUM HIGH CRITICAL])
  end
end
