# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema do
  let(:user) { build :user }

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

  describe '.execute' do
    context 'for different types of users' do
      context 'when no context' do
        it 'returns DEFAULT_MAX_COMPLEXITY' do
          expect(GraphQL::Schema)
            .to receive(:execute)
            .with('query', hash_including(max_complexity: GitlabSchema::DEFAULT_MAX_COMPLEXITY))

          described_class.execute('query')
        end
      end

      context 'when no user' do
        it 'returns DEFAULT_MAX_COMPLEXITY' do
          expect(GraphQL::Schema)
            .to receive(:execute)
            .with('query', hash_including(max_complexity: GitlabSchema::DEFAULT_MAX_COMPLEXITY))

          described_class.execute('query', context: {})
        end

        it 'returns DEFAULT_MAX_DEPTH' do
          expect(GraphQL::Schema)
            .to receive(:execute)
            .with('query', hash_including(max_depth: GitlabSchema::DEFAULT_MAX_DEPTH))

          described_class.execute('query', context: {})
        end
      end

      context 'when a logged in user' do
        it 'returns AUTHENTICATED_COMPLEXITY' do
          expect(GraphQL::Schema).to receive(:execute).with('query', hash_including(max_complexity: GitlabSchema::AUTHENTICATED_COMPLEXITY))

          described_class.execute('query', context: { current_user: user })
        end

        it 'returns AUTHENTICATED_MAX_DEPTH' do
          expect(GraphQL::Schema).to receive(:execute).with('query', hash_including(max_depth: GitlabSchema::AUTHENTICATED_MAX_DEPTH))

          described_class.execute('query', context: { current_user: user })
        end
      end

      context 'when an admin user' do
        it 'returns ADMIN_COMPLEXITY' do
          user = build :user, :admin

          expect(GraphQL::Schema).to receive(:execute).with('query', hash_including(max_complexity: GitlabSchema::ADMIN_COMPLEXITY))

          described_class.execute('query', context: { current_user: user })
        end
      end

      context 'when max_complexity passed on the query' do
        it 'returns what was passed on the query' do
          expect(GraphQL::Schema).to receive(:execute).with('query', hash_including(max_complexity: 1234))

          described_class.execute('query', max_complexity: 1234)
        end
      end

      context 'when max_depth passed on the query' do
        it 'returns what was passed on the query' do
          expect(GraphQL::Schema).to receive(:execute).with('query', hash_including(max_depth: 1234))

          described_class.execute('query', max_depth: 1234)
        end
      end
    end
  end

  def field_instrumenters
    described_class.instrumenters[:field] + described_class.instrumenters[:field_after_built_ins]
  end
end
