# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::RunnerType do
  specify { expect(described_class.graphql_name).to eq('CiRunner') }

  it 'contains attributes related to a runner' do
    expected_fields = %w[
      id description contacted_at maximum_timeout access_level active status
      version short_sha revision locked run_untagged ip_address runner_type tag_list
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
