# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentTokensFinder do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:agent) { create(:cluster_agent, project: project) }
    let(:user) { create(:user, maintainer_of: project) }

    let_it_be(:active_agent_tokens) do
      Array.new(2) { create(:cluster_agent_token, agent: agent) }
    end

    let_it_be(:revoked_agent_tokens) do
      create_list(:cluster_agent_token, 2, :revoked, agent: agent)
    end

    before_all do
      # set up a token under a different agent as a way to verify
      # that only tokens of a given agent are included in the result
      create(:cluster_agent_token, agent: create(:cluster_agent))
    end

    subject(:execute) { described_class.new(agent, user).execute }

    it { is_expected.to match_array(active_agent_tokens + revoked_agent_tokens) }

    context 'when filtering by status=active' do
      subject(:execute) { described_class.new(agent, user, status: 'active').execute }

      it { is_expected.to match_array(active_agent_tokens) }
    end

    context 'when filtering by status=revoked' do
      subject(:execute) { described_class.new(agent, user, status: 'revoked').execute }

      it { is_expected.to match_array(revoked_agent_tokens) }
    end

    context 'when filtering by an unrecognised status' do
      subject(:execute) { described_class.new(agent, user, status: 'dummy').execute }

      it { is_expected.to be_empty }
    end

    context 'when user does not have permission' do
      let(:user) { create(:user) }

      before do
        project.add_reporter(user)
      end

      it { is_expected.to eq ::Clusters::AgentToken.none }
    end

    context 'when current_user is nil' do
      it 'returns an empty list' do
        result = described_class.new(agent, nil).execute
        expect(result).to eq ::Clusters::AgentToken.none
      end
    end

    context 'when agent is nil' do
      it 'returns an empty list' do
        result = described_class.new(nil, user).execute
        expect(result).to eq ::Clusters::AgentToken.none
      end
    end
  end
end
