# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Kas::AgentConfigurationsResolver do
  include GraphqlHelpers

  it { expect(described_class.type).to eq(Types::Kas::AgentConfigurationType.connection_type) }
  it { expect(described_class.null).to be_truthy }
  it { expect(described_class.calls_gitaly?).to eq(true) }

  describe '#resolve' do
    let_it_be(:project) { create(:project) }

    let(:user) { create(:user, maintainer_of: project) }
    let(:ctx) { Hash(current_user: user) }

    let(:agent1) { double }
    let(:agent2) { double }
    let(:kas_client) { instance_double(Gitlab::Kas::Client, list_agent_config_files: [agent1, agent2]) }

    subject { resolve(described_class, obj: project, ctx: ctx) }

    before do
      allow(Gitlab::Kas::Client).to receive(:new).and_return(kas_client)
    end

    it 'returns agents configured for the project' do
      expect(subject.items).to contain_exactly(agent1, agent2)
    end

    context 'an error is returned from the KAS client' do
      before do
        allow(kas_client).to receive(:list_agent_config_files).and_raise(GRPC::DeadlineExceeded)
      end

      it 'generates a graphql error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable, 'GRPC::DeadlineExceeded') do
          subject
        end
      end
    end

    context 'user does not have permission' do
      let(:user) { create(:user) }

      it { expect(subject.items).to be_empty }
    end
  end
end
