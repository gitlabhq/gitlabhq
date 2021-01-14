# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageComposerJsonType'] do
  it { expect(described_class.graphql_name).to eq('PackageComposerJsonType') }

  it 'includes composer json files' do
    expected_fields = %w[
      name type license version
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
