# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ClusterAgentsHelper do
  describe '#js_cluster_agent_details_data' do
    let_it_be(:project) { create(:project) }

    let(:agent_name) { 'agent-name' }

    subject { helper.js_cluster_agent_details_data(agent_name, project) }

    it 'returns name' do
      expect(subject[:agent_name]).to eq(agent_name)
    end

    it 'returns project path' do
      expect(subject[:project_path]).to eq(project.full_path)
    end
  end
end
