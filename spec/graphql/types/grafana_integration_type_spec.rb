# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['GrafanaIntegration'] do
  let(:expected_fields) do
    %i[
      id
      grafana_url
      token
      enabled
      created_at
      updated_at
    ]
  end

  it { expect(described_class.graphql_name).to eq('GrafanaIntegration') }

  it { expect(described_class).to require_graphql_authorizations(:admin_operations) }

  it { is_expected.to have_graphql_fields(*expected_fields) }
end
