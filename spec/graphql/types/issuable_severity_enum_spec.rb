# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::IssuableSeverityEnum do
  specify { expect(described_class.graphql_name).to eq('IssuableSeverity') }

  it 'exposes all the existing issuable severity values' do
    expect(described_class.values.keys).to contain_exactly(
      *%w[UNKNOWN LOW MEDIUM HIGH CRITICAL]
    )
  end
end
