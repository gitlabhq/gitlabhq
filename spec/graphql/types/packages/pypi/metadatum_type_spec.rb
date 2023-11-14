# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PypiMetadata'] do
  it 'includes pypi metadatum fields' do
    expected_fields = %w[
      author_email
      description
      description_content_type
      id
      keywords
      metadata_version
      required_python
      summary
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
