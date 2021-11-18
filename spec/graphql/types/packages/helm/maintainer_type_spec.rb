# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageHelmMaintainerType'] do
  it { expect(described_class.graphql_name).to eq('PackageHelmMaintainerType') }

  it 'includes helm maintainer fields' do
    expected_fields = %w[
      name email url
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
