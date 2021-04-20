# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ConanFileMetadata'] do
  it 'includes conan file metadatum fields' do
    expected_fields = %w[
      id created_at updated_at recipe_revision package_revision conan_package_reference conan_file_type
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
