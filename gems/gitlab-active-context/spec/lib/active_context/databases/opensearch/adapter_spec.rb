# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Opensearch::Adapter do
  let(:options) { { url: 'http://localhost:9200' } }

  subject(:adapter) { described_class.new(options) }

  it 'delegates search to client' do
    query = ActiveContext::Query.filter(foo: :bar)
    expect(adapter.client).to receive(:search).with(query)

    adapter.search(query)
  end

  describe '#prefix' do
    it 'returns default prefix when not specified' do
      expect(adapter.prefix).to eq('gitlab_active_context')
    end

    it 'returns configured prefix' do
      adapter = described_class.new(options.merge(prefix: 'custom'))
      expect(adapter.prefix).to eq('custom')
    end
  end
end
