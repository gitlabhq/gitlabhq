# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Elasticsearch::QueryResult do
  let(:collection) { double(:collection) }
  let(:user) { double(:user) }
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

  subject(:query_result) { described_class.new(result: elasticsearch_result, collection: collection, user: user) }

  before do
    allow(collection).to receive_messages(redact_unauthorized_results!: [[], []])
  end

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

  describe '#authorized_results' do
    let(:authorized_records) { [{ 'id' => 1, 'name' => 'test1' }] }

    before do
      allow(collection).to receive(:redact_unauthorized_results!).with(query_result).and_return(authorized_records)
    end

    it 'delegates to collection.redact_unauthorized_results!' do
      expect(query_result.authorized_results).to eq(authorized_records)
      expect(collection).to have_received(:redact_unauthorized_results!).with(query_result)
    end

    it 'memoizes the result' do
      2.times { query_result.authorized_results }

      expect(collection).to have_received(:redact_unauthorized_results!).with(query_result).once
    end
  end
end
