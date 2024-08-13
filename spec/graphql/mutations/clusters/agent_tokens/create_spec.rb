# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Clusters::AgentTokens::Create do
  include GraphqlHelpers

  let_it_be(:cluster_agent) { create(:cluster_agent) }
  let_it_be(:current_user) { create(:user) }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:create_cluster) }

  describe '#resolve' do
    let(:description) { 'new token!' }
    let(:name) { 'new name' }

    subject { mutation.resolve(cluster_agent_id: cluster_agent.to_global_id, description: description, name: name) }

    context 'without token permissions' do
      it 'raises an error if the resource is not accessible to the user' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'with user permissions' do
      before do
        cluster_agent.project.add_maintainer(current_user)
      end

      it 'creates a new token', :aggregate_failures do
        expect { subject }.to change { ::Clusters::AgentToken.count }.by(1)
        expect(subject[:errors]).to eq([])
      end

      it 'returns token information', :aggregate_failures do
        token = subject[:token]

        expect(subject[:secret]).not_to be_nil
        expect(token.created_by_user).to eq(current_user)
        expect(token.description).to eq(description)
        expect(token.name).to eq(name)
      end

      context 'when the active agent tokens limit is reached' do
        before do
          create(:cluster_agent_token, agent: cluster_agent)
          create(:cluster_agent_token, agent: cluster_agent)
        end

        it 'raises an error' do
          expect { subject }.not_to change { ::Clusters::AgentToken.count }
          expect(subject[:errors]).to eq(["An agent can have only two active tokens at a time"])
        end
      end
    end
  end
end
