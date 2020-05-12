# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Environment'] do
  specify { expect(described_class.graphql_name).to eq('Environment') }

  it 'has the expected fields' do
    expected_fields = %w[
      name id state metrics_dashboard
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_environment) }
end
