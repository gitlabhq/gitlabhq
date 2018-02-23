require 'spec_helper'

describe GitlabSchema do
  it 'uses batch loading' do
    expect(field_instrumenters).to include(BatchLoader::GraphQL)
  end

  it 'enables the preload instrumenter' do
    expect(field_instrumenters).to include(instance_of(::GraphQL::Preload::Instrument))
  end

  it 'enables the authorization instrumenter' do
    expect(field_instrumenters).to include(instance_of(::Gitlab::Graphql::Authorize))
  end

  it 'has the base mutation' do
    expect(described_class.mutation).to eq(::Types::MutationType)
  end

  it 'has the base query' do
    expect(described_class.query).to eq(::Types::QueryType)
  end

  def field_instrumenters
    described_class.instrumenters[:field]
  end
end
