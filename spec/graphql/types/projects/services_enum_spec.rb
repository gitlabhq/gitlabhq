# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ServiceType'] do
  specify { expect(described_class.graphql_name).to eq('ServiceType') }

  it 'exposes all the existing project services' do
    expect(described_class.values.keys).to match_array(available_services_enum)
  end
end

def available_services_enum
  ::Service.available_services_types(include_dev: false).map(&:underscore).map(&:upcase)
end
