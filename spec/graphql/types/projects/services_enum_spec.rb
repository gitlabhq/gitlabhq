# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['ServiceType'] do
  specify { expect(described_class.graphql_name).to eq('ServiceType') }

  it 'exposes all the existing project services' do
    expect(described_class.values.keys).to match_array(available_services_enum)
  end
end

def available_services_enum
  ::Service.services_types.map(&:underscore).map(&:upcase)
end
