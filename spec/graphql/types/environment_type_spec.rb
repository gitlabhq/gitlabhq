# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Environment'] do
  it { expect(described_class.graphql_name).to eq('Environment') }

  it 'has the expected fields' do
    expected_fields = %w[
      name id
    ]

    is_expected.to have_graphql_fields(*expected_fields)
  end

  it { is_expected.to require_graphql_authorizations(:read_environment) }
end
