# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentTokensFinder do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let(:user) { create(:user, maintainer_projects: [project]) }
    let(:agent) { create(:cluster_agent, project: project) }
    let(:agent_id) { agent.id }

    let!(:matching_agent_tokens) do
      [
        create(:cluster_agent_token, agent: agent),
        create(:cluster_agent_token, :revoked, agent: agent)
      ]
    end

    subject(:execute) { described_class.new(project, user, agent_id).execute }

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

      it 'raises an error' do
        expect { execute }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when agent does not exist' do
      let(:agent_id) { non_existing_record_id }

      it 'raises an error' do
        expect { execute }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
