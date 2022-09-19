# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ComposerMetadata'] do
  it 'includes composer metadatum fields' do
    expected_fields = %w[
      target_sha composer_json
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
