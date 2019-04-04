# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema do
  it 'uses batch loading' do
    expect(field_instrumenters).to include(BatchLoader::GraphQL)
  end

  it 'enables the preload instrumenter' do
    expect(field_instrumenters).to include(BatchLoader::GraphQL)
  end

  it 'enables the authorization instrumenter' do
    expect(field_instrumenters).to include(instance_of(::Gitlab::Graphql::Authorize::Instrumentation))
  end

  it 'enables using presenters' do
    expect(field_instrumenters).to include(instance_of(::Gitlab::Graphql::Present::Instrumentation))
  end

  it 'has the base mutation' do
    expect(described_class.mutation).to eq(::Types::MutationType.to_graphql)
  end

  it 'has the base query' do
    expect(described_class.query).to eq(::Types::QueryType.to_graphql)
  end

  it 'paginates active record relations using `Gitlab::Graphql::Connections::KeysetConnection`' do
    connection = GraphQL::Relay::BaseConnection::CONNECTION_IMPLEMENTATIONS[ActiveRecord::Relation.name]

    expect(connection).to eq(Gitlab::Graphql::Connections::KeysetConnection)
  end

  context 'for different types of users' do
    it 'returns DEFAULT_MAX_COMPLEXITY for no context' do
      expect(GraphQL::Schema)
        .to receive(:execute)
        .with('query', hash_including(max_complexity: GitlabSchema::DEFAULT_MAX_COMPLEXITY))

      described_class.execute('query')
    end

    it 'returns DEFAULT_MAX_COMPLEXITY for no user' do
      expect(GraphQL::Schema)
        .to receive(:execute)
        .with('query', hash_including(max_complexity: GitlabSchema::DEFAULT_MAX_COMPLEXITY))

      described_class.execute('query', context: {})
    end

    it 'returns AUTHENTICATED_COMPLEXITY for a logged in user' do
      user = build :user

      expect(GraphQL::Schema).to receive(:execute).with('query', hash_including(max_complexity: GitlabSchema::AUTHENTICATED_COMPLEXITY))

      described_class.execute('query', context: { current_user: user })
    end

    it 'returns ADMIN_COMPLEXITY for an admin user' do
      user = build :user, :admin

      expect(GraphQL::Schema).to receive(:execute).with('query', hash_including(max_complexity: GitlabSchema::ADMIN_COMPLEXITY))

      described_class.execute('query', context: { current_user: user })
    end

    it 'returns what was passed on the query' do
      expect(GraphQL::Schema).to receive(:execute).with('query', { max_complexity: 1234 })

      described_class.execute('query', max_complexity: 1234)
    end
  end

  def field_instrumenters
    described_class.instrumenters[:field]
  end
end
