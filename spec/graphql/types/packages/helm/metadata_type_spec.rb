# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageHelmMetadataType'] do
  it { expect(described_class.graphql_name).to eq('PackageHelmMetadataType') }

  it 'includes helm json fields' do
    expected_fields = %w[
      name home sources version description keywords maintainers icon apiVersion condition tags appVersion deprecated annotations kubeVersion dependencies type
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
