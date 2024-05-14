# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Clusters::AgentActivityEventsResolver do
  include GraphqlHelpers

  it { expect(described_class.type).to eq(Types::Clusters::AgentActivityEventType) }
  it { expect(described_class.null).to be_truthy }

  describe '#resolve' do
    let_it_be(:agent) { create(:cluster_agent) }

    let(:user) { create(:user, maintainer_of: agent.project) }
    let(:ctx) { { current_user: user } }
    let(:events) { double }

    before do
      allow(agent).to receive(:activity_events).and_return(events)
    end

    subject { resolve(described_class, obj: agent, ctx: ctx) }

    it 'returns events associated with the agent' do
      expect(subject).to eq(events)
    end

    context 'user does not have permission' do
      let(:user) { create(:user, developer_of: agent.project) }

      it { is_expected.to be_empty }
    end
  end
end
