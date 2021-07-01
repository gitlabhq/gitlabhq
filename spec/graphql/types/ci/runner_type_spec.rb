# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiRunner'] do
  specify { expect(described_class.graphql_name).to eq('CiRunner') }

  specify { expect(described_class).to require_graphql_authorizations(:read_runner) }

  it 'contains attributes related to a runner' do
    expected_fields = %w[
      id description contacted_at maximum_timeout access_level active status
      version short_sha revision locked run_untagged ip_address runner_type tag_list
      project_count job_count
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
