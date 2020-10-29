# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AvailabilityEnum'] do
  specify { expect(described_class.graphql_name).to eq('AvailabilityEnum') }

  it 'exposes all the existing access levels' do
    expect(described_class.values.keys).to match_array(%w[NOT_SET BUSY])
  end
end
