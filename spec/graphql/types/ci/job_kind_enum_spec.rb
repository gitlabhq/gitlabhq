# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiJobKind'] do
  it 'exposes some job type values' do
    expect(described_class.values.keys).to match_array(
      %w[BRIDGE BUILD]
    )
  end
end
