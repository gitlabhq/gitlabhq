# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ClusterAgentToken'] do
  let(:fields) { %i[cluster_agent created_at created_by_user description id last_used_at name] }

  it { expect(described_class.graphql_name).to eq('ClusterAgentToken') }

  it { expect(described_class).to require_graphql_authorizations(:admin_cluster) }

  it { expect(described_class).to have_graphql_fields(fields) }
end
