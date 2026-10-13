# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageDependencyType'] do
  it 'exposes all depeendency type values' do
    expect(described_class.values.keys).to match_array(
      %w[DEPENDENCIES DEV_DEPENDENCIES BUNDLE_DEPENDENCIES PEER_DEPENDENCIES]
    )
  end
end
