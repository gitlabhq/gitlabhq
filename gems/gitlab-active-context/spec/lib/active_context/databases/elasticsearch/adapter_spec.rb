# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Elasticsearch::Adapter do
  let(:options) { { url: 'http://localhost:9200' } }

  subject(:adapter) { described_class.new(options) }

  it 'delegates search to client' do
    query = ActiveContext::Query.filter(foo: :bar)
    expect(adapter.client).to receive(:search).with(query)

    adapter.search(query)
  end
end
