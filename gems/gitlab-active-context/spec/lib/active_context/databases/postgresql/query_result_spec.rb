# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Postgresql::QueryResult do
  let(:pg_result) { instance_double(PG::Result) }

  subject(:query_result) { described_class.new(pg_result) }

  describe '#each' do
    it 'yields each row' do
      rows = [
        { 'id' => 1, 'name' => 'test1' },
        { 'id' => 2, 'name' => 'test2' }
      ]

      allow(pg_result).to receive(:each).and_yield(rows[0]).and_yield(rows[1])

      expect { |b| query_result.each(&b) }.to yield_successive_args(*rows)
    end

    it 'returns enumerator when no block given' do
      expect(query_result.each).to be_a(Enumerator)
    end
  end

  describe '#count' do
    it 'returns number of tuples' do
      allow(pg_result).to receive(:ntuples).and_return(5)
      expect(query_result.count).to eq(5)
    end
  end

  describe '#clear' do
    context 'when pg_result responds to clear' do
      before do
        allow(pg_result).to receive(:respond_to?).with(:clear).and_return(true)
      end

      it 'clears the result' do
        expect(pg_result).to receive(:clear)
        query_result.clear
      end
    end

    context 'when pg_result does not respond to clear' do
      before do
        allow(pg_result).to receive(:respond_to?).with(:clear).and_return(false)
      end

      it 'does nothing' do
        expect(pg_result).not_to receive(:clear)
        query_result.clear
      end
    end
  end
end
