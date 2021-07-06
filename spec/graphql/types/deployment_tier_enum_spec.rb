# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::DeploymentTierEnum do
  it 'includes a value for each supported environment tier' do
    expect(described_class.values).to match(
      'PRODUCTION' => have_attributes(value: :production),
      'STAGING' => have_attributes(value: :staging),
      'TESTING' => have_attributes(value: :testing),
      'DEVELOPMENT' => have_attributes(value: :development),
      'OTHER' => have_attributes(value: :other)
    )
  end
end
