# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Clusters::AgentTokens::Delete do
  let(:token) { create(:cluster_agent_token) }
  let(:user) { create(:user) }

  let(:mutation) do
    described_class.new(
      object: double,
      context: { current_user: user },
      field: double
    )
  end

  it { expect(described_class.graphql_name).to eq('ClusterAgentTokenDelete') }
  it { expect(described_class).to require_graphql_authorizations(:admin_cluster) }

  describe '#resolve' do
    let(:global_id) { token.to_global_id }

    subject { mutation.resolve(id: global_id) }

    context 'without user permissions' do
      it 'fails to delete the cluster agent', :aggregate_failures do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        expect { token.reload }.not_to raise_error
      end
    end

    context 'with user permissions' do
      before do
        token.agent.project.add_maintainer(user)
      end

      it 'deletes a cluster agent', :aggregate_failures do
        expect { subject }.to change { ::Clusters::AgentToken.count }.by(-1)
        expect { token.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with invalid params' do
      let(:global_id) { token.id }

      it 'raises an error if the cluster agent id is invalid', :aggregate_failures do
        expect { subject }.to raise_error(::GraphQL::CoercionError)
        expect { token.reload }.not_to raise_error
      end
    end
  end
end
