# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MavenMetadata'] do
  it 'includes maven metadatum fields' do
    expected_fields = %w[
      id created_at updated_at path app_group app_version app_name
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
