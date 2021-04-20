# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ConanMetadata'] do
  it 'includes conan metadatum fields' do
    expected_fields = %w[
      id created_at updated_at package_username package_channel recipe recipe_path
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
