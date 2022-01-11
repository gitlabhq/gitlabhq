# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Clusters::AgentTokensResolver do
  include GraphqlHelpers

  it { expect(described_class.type).to eq(Types::Clusters::AgentTokenType) }
  it { expect(described_class.null).to be_truthy }
  it { expect(described_class.arguments.keys).to contain_exactly('status') }

  describe '#resolve' do
    let(:agent) { create(:cluster_agent) }
    let(:user) { create(:user, maintainer_projects: [agent.project]) }
    let(:ctx) { Hash(current_user: user) }

    let!(:matching_token1) { create(:cluster_agent_token, agent: agent, last_used_at: 5.days.ago) }
    let!(:matching_token2) { create(:cluster_agent_token, agent: agent, last_used_at: 2.days.ago) }
    let!(:other_token) { create(:cluster_agent_token) }

    subject { resolve(described_class, obj: agent, ctx: ctx) }

    it 'returns tokens associated with the agent, ordered by last_used_at' do
      expect(subject).to eq([matching_token2, matching_token1])
    end

    context 'token status is specified' do
      let!(:revoked_token) { create(:cluster_agent_token, :revoked, agent: agent) }

      subject { resolve(described_class, obj: agent, ctx: ctx, args: { status: 'revoked' }) }

      it { is_expected.to contain_exactly(revoked_token) }
    end

    context 'user does not have permission' do
      let(:user) { create(:user, developer_projects: [agent.project]) }

      it { is_expected.to be_empty }
    end
  end
end
