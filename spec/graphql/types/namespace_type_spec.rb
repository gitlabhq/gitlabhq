# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Namespace'] do
  it { expect(described_class.graphql_name).to eq('Namespace') }

  it 'has the expected fields' do
    expected_fields = %w[
      id name path full_name full_path description description_html visibility
      lfs_enabled request_access_enabled projects
    ]

    is_expected.to have_graphql_fields(*expected_fields)
  end

  it { is_expected.to require_graphql_authorizations(:read_namespace) }
end
