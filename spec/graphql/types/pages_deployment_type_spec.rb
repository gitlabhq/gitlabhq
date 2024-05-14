# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PagesDeployment'], feature_category: :pages do
  specify { expect(described_class.graphql_name).to eq('PagesDeployment') }

  it 'has the expected fields' do
    expected_fields = %w[
      active ci_build_id created_at deleted_at file_count id path_prefix project
      root_directory size updated_at url
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_pages_deployments) }
end
