# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::JobAnalyticsResolver, feature_category: :fleet_visibility do
  include GraphqlHelpers

  it { expect(described_class.type).to eq(Types::Ci::JobAnalyticsType.connection_type) }
  it { expect(described_class.extras).to include(:lookahead) }
  it { expect(described_class.null).to be(true) }

  describe 'arguments' do
    subject(:resolver_arguments) { described_class.arguments }

    it 'has expected arguments' do
      expect(resolver_arguments.keys).to contain_exactly(
        'nameSearch',
        'ref',
        'source',
        'fromTime',
        'toTime',
        'sort'
      )
    end

    it 'has expected argument types' do
      expect(resolver_arguments['nameSearch'].type).to eq(GraphQL::Types::String)
      expect(resolver_arguments['ref'].type).to eq(GraphQL::Types::String)
      expect(resolver_arguments['source'].type.graphql_name).to eq('CiPipelineSources')
      expect(resolver_arguments['fromTime'].type.graphql_name).to eq('Time')
      expect(resolver_arguments['toTime'].type.graphql_name).to eq('Time')
      expect(resolver_arguments['sort'].type.graphql_name).to eq('CiJobAnalyticsSort')
    end
  end
end
