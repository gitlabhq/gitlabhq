# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Clusters::AgentTokensResolver do
  include GraphqlHelpers

  it { expect(described_class.type).to eq(Types::Clusters::AgentTokenType.connection_type) }
  it { expect(described_class.null).to be_truthy }
  it { expect(described_class.arguments.keys).to be_empty }

  describe '#resolve' do
    let(:agent) { create(:cluster_agent) }
    let(:user) { create(:user, developer_of: agent.project) }
    let(:ctx) { Hash(current_user: user) }

    let!(:matching_token1) { create(:cluster_agent_token, agent: agent, last_used_at: 5.days.ago) }
    let!(:matching_token2) { create(:cluster_agent_token, agent: agent, last_used_at: 2.days.ago) }
    let!(:revoked_token) { create(:cluster_agent_token, :revoked, agent: agent) }
    let!(:other_token) { create(:cluster_agent_token) }

    subject { resolve(described_class, obj: agent, ctx: ctx) }

    it 'returns active tokens associated with the agent, ordered by last_used_at' do
      expect(subject.items).to eq([matching_token2, matching_token1])
    end

    context 'user does not have permission' do
      let(:user) { create(:user) }

      before do
        agent.project.add_reporter(user)
      end

      it { is_expected.to be_empty }
    end
  end
end
