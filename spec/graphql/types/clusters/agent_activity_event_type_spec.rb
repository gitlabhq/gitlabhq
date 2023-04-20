# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ClusterAgentActivityEvent'] do
  let(:fields) { %i[recorded_at kind level user agent_token] }

  it { expect(described_class.graphql_name).to eq('ClusterAgentActivityEvent') }
  it { expect(described_class).to require_graphql_authorizations(:read_cluster_agent) }
  it { expect(described_class).to have_graphql_fields(fields) }
end
