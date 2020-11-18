# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['GrafanaIntegration'] do
  let(:expected_fields) do
    %i[
      id
      grafana_url
      enabled
      created_at
      updated_at
    ]
  end

  specify { expect(described_class.graphql_name).to eq('GrafanaIntegration') }

  specify { expect(described_class).to require_graphql_authorizations(:admin_operations) }

  specify { expect(described_class).to have_graphql_fields(*expected_fields) }
end
