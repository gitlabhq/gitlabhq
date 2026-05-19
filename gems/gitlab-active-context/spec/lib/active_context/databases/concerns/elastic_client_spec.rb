# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Concerns::ElasticClient do
  let(:test_class) do
    Class.new do
      include ActiveContext::Databases::Concerns::ElasticClient
    end
  end

  subject(:instance) { test_class.new }

  describe '#add_source_fields' do
    let(:es_query) { { query: { match_all: {} } } }

    context 'when source_fields is nil' do
      it 'returns the query unchanged' do
        expect(instance.add_source_fields(es_query, nil)).to eq(es_query)
      end
    end

    context 'when source_fields is provided' do
      it 'merges _source includes into the query' do
        result = instance.add_source_fields(es_query, %w[title content])

        expect(result).to eq(
          query: { match_all: {} },
          _source: { includes: %w[title content] }
        )
      end

      it 'does not mutate the original query' do
        original = es_query.dup
        instance.add_source_fields(es_query, ['title'])

        expect(es_query).to eq(original)
      end
    end
  end
end
