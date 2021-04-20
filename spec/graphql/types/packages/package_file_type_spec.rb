# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageFile'] do
  it 'includes package file fields' do
    expected_fields = %w[
      id file_name created_at updated_at size file_name download_path file_md5 file_sha1 file_sha256 file_metadata
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
