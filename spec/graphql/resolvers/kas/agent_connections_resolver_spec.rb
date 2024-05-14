# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Kas::AgentConnectionsResolver do
  include GraphqlHelpers

  it { expect(described_class.type).to eq(Types::Kas::AgentConnectionType) }
  it { expect(described_class.null).to be_truthy }

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:agent1) { create(:cluster_agent, project: project) }
    let_it_be(:agent2) { create(:cluster_agent, project: project) }

    let(:user) { create(:user, maintainer_of: project) }
    let(:ctx) { Hash(current_user: user) }

    let(:connection1) { double(agent_id: agent1.id) }
    let(:connection2) { double(agent_id: agent1.id) }
    let(:connection3) { double(agent_id: agent2.id) }
    let(:connected_agents) { [connection1, connection2, connection3] }
    let(:kas_client) { instance_double(Gitlab::Kas::Client, get_connected_agents_by_agent_ids: connected_agents) }

    subject do
      batch_sync do
        resolve(described_class, obj: agent1, ctx: ctx)
      end
    end

    before do
      allow(Gitlab::Kas::Client).to receive(:new).and_return(kas_client)
    end

    it 'returns active connections for the agent' do
      expect(subject).to contain_exactly(connection1, connection2)
    end

    it 'queries KAS once when multiple agents are requested' do
      expect(kas_client).to receive(:get_connected_agents_by_agent_ids).once

      response = batch_sync do
        resolve(described_class, obj: agent1, ctx: ctx)
        resolve(described_class, obj: agent2, ctx: ctx)
      end

      expect(response).to contain_exactly(connection3)
    end

    context 'an error is returned from the KAS client' do
      before do
        allow(kas_client).to receive(:get_connected_agents_by_agent_ids).and_raise(GRPC::DeadlineExceeded)
      end

      it 'raises a graphql error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable, 'GRPC::DeadlineExceeded')
      end
    end

    context 'user does not have permission' do
      let(:user) { create(:user) }

      it { is_expected.to be_empty }
    end
  end
end
