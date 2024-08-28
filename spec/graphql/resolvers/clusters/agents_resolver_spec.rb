# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Clusters::AgentsResolver, feature_category: :deployment_management do
  include GraphqlHelpers

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::Clusters::AgentType.connection_type)
  end

  specify do
    expect(described_class.extras).to include(:lookahead)
  end

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:maintainer) { create(:user, developer_of: project) }
    let_it_be(:reporter) { create(:user) }
    let_it_be(:agents) { create_list(:cluster_agent, 2, project: project) }

    before do
      project.add_reporter(reporter)
    end

    let(:ctx) { { current_user: current_user } }

    subject { resolve_agents }

    context 'the current user has access to clusters' do
      let(:current_user) { maintainer }

      it 'finds all agents' do
        expect(subject).to match_array(agents)
      end
    end

    context 'the current user does not have access to clusters' do
      let(:current_user) { reporter }

      it 'returns an empty result' do
        expect(subject).to be_empty
      end
    end
  end

  def resolve_agents(args = {})
    resolve(described_class, obj: project, ctx: ctx, lookahead: positive_lookahead, args: args)
  end
end

RSpec.describe Resolvers::Clusters::AgentsResolver.single, feature_category: :deployment_management do
  it { expect(described_class).to be < Resolvers::Clusters::AgentsResolver }

  it { expect(described_class.type).to eq(::Types::Clusters::AgentType) }
  it { expect(described_class.null).to eq(true) }
  it { expect(described_class.extras).to include(:lookahead) }

  describe 'arguments' do
    subject { described_class.arguments[argument] }

    describe 'name' do
      let(:argument) { 'name' }

      it do
        expect(subject).to be_present
        expect(subject.type).to be_kind_of GraphQL::Schema::NonNull
        expect(subject.type.unwrap).to eq GraphQL::Types::String
        expect(subject.description).to be_present
      end
    end
  end
end
