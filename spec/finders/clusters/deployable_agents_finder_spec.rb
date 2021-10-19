# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::DeployableAgentsFinder do
  describe '#execute' do
    let_it_be(:agent) { create(:cluster_agent) }

    let(:project) { agent.project }

    subject { described_class.new(project).execute }

    it { is_expected.to contain_exactly(agent) }
  end
end
