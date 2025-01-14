# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Elasticsearch::QueryResult do
  let(:elasticsearch_result) do
    {
      'hits' => {
        'total' => { 'value' => 2 },
        'hits' => [
          { '_source' => { 'id' => 1, 'name' => 'test1' } },
          { '_source' => { 'id' => 2, 'name' => 'test2' } }
        ]
      }
    }
  end

  subject(:query_result) { described_class.new(elasticsearch_result) }

  describe '#count' do
    it 'returns the total number of hits' do
      expect(query_result.count).to eq(2)
    end
  end

  describe '#each' do
    it 'yields each hit source' do
      expected_sources = [
        { 'id' => 1, 'name' => 'test1' },
        { 'id' => 2, 'name' => 'test2' }
      ]

      expect { |b| query_result.each(&b) }.to yield_successive_args(*expected_sources)
    end

    it 'returns an enumerator when no block is given' do
      expect(query_result.each).to be_a(Enumerator)
    end
  end

  describe 'enumerable behavior' do
    it 'implements Enumerable methods' do
      expect(query_result.map { |hit| hit['id'] }).to eq([1, 2]) # rubocop: disable Rails/Pluck -- pluck not implemented
      expect(query_result.select { |hit| hit['id'] == 1 }).to eq([{ 'id' => 1, 'name' => 'test1' }])
    end
  end
end
