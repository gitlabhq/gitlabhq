# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ServiceType'] do
  it 'exposes all the existing project services' do
    expect(described_class.values.keys).to match_array(available_services_enum)
  end

  def available_services_enum
    ::Integration.available_integration_types(include_dev: false).map(&:underscore).map(&:upcase)
  end
end
