# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PrometheusAlert'] do
  specify { expect(described_class.graphql_name).to eq('PrometheusAlert') }

  it 'has the expected fields' do
    expected_fields = %w[
      id humanized_text
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:admin_operations) }
end
