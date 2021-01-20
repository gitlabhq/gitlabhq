# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageComposerMetadatumType'] do
  it { expect(described_class.graphql_name).to eq('PackageComposerMetadatumType') }

  it 'includes composer metadatum fields' do
    expected_fields = %w[
     target_sha composer_json
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
