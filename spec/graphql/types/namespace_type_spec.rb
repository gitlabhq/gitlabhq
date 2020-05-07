# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Namespace'] do
  specify { expect(described_class.graphql_name).to eq('Namespace') }

  it 'has the expected fields' do
    expected_fields = %w[
      id name path full_name full_path description description_html visibility
      lfs_enabled request_access_enabled projects root_storage_statistics
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_namespace) }
end
