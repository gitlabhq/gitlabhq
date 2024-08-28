# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ClusterAgentUrlConfiguration'], feature_category: :deployment_management do
  include GraphqlHelpers

  let(:fields) { %i[cluster_agent id url ca_cert tls_host public_key client_cert] }

  it { expect(described_class.graphql_name).to eq('ClusterAgentUrlConfiguration') }

  it { expect(described_class).to require_graphql_authorizations(:read_cluster_agent) }

  it { expect(described_class).to have_graphql_fields(fields) }

  describe '#cluster_agent' do
    let(:cluster_agent) { create(:cluster_agent) }
    let(:current_user) { create(:user, maintainer_of: cluster_agent.project) }
    let(:url_configuration) { create(:cluster_agent_url_configuration, agent: cluster_agent) }

    subject do
      resolve_field(:cluster_agent, url_configuration, current_user: current_user, object_type: described_class)
        .value
    end

    it 'returns the cluster agent' do
      is_expected.to eq(cluster_agent)
    end
  end
end
