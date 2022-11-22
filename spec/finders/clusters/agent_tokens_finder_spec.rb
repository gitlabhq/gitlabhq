# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentTokensFinder do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let(:user) { create(:user, maintainer_projects: [project]) }
    let(:agent) { create(:cluster_agent, project: project) }

    let!(:matching_agent_tokens) do
      [
        create(:cluster_agent_token, agent: agent),
        create(:cluster_agent_token, :revoked, agent: agent)
      ]
    end

    subject(:execute) { described_class.new(agent, user).execute }

    it 'returns the tokens of the specified agent' do
      # creating a token in a different agent to make sure it will not be included in the result
      create(:cluster_agent_token, agent: create(:cluster_agent))

      expect(execute).to match_array(matching_agent_tokens)
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
