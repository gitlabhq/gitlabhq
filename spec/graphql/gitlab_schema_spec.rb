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

  def field_instrumenters
    described_class.instrumenters[:field]
  end
end
