# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Client::Query do
  subject(:query) { described_class.new(raw_query: raw_query, placeholders: placeholders) }

  let(:sql) { query.to_sql }
  let(:redacted_sql) { query.to_redacted_sql }

  context 'when using no placeholders' do
    let(:raw_query) { 'SELECT * FROM events' }
    let(:placeholders) { nil }

    it { expect(sql).to eq(raw_query) }
    it { expect(redacted_sql).to eq(raw_query) }

    context 'when placeholders is an empty hash' do
      let(:placeholders) { {} }

      it { expect(sql).to eq(raw_query) }
      it { expect(redacted_sql).to eq(raw_query) }
    end
  end

  context 'when placeholders are given' do
    let(:raw_query) { 'SELECT * FROM events WHERE id = {id:UInt64}' }
    let(:placeholders) { { id: 1 } }

    it { expect(sql).to eq(raw_query) }
    it { expect(redacted_sql).to eq('SELECT * FROM events WHERE id = $1') }
  end

  context 'when multiple placeholders are given' do
    let(:raw_query) do
      <<~SQL.squish
        SELECT *
        FROM events
        WHERE
        id = {id:UInt64} AND
        title = {some_title:String} AND
        another_id = {id:UInt64}
      SQL
    end

    let(:placeholders) { { id: 1, some_title: "'title'" } }

    it do
      expect(sql).to eq(raw_query)
    end

    it do
      expect(redacted_sql).to eq(
        <<~SQL.squish
          SELECT *
          FROM events
          WHERE
          id = $1 AND
          title = $2 AND
          another_id = $3
        SQL
      )
    end
  end

  context 'when dealing with subqueries' do
    let(:raw_query) { 'SELECT * FROM events WHERE id < {min_id:UInt64} AND id IN ({q:Subquery})' }

    let(:subquery) do
      described_class.new(raw_query: 'SELECT id FROM events WHERE id > {max_id:UInt64}', placeholders: { max_id: 11 })
    end

    let(:placeholders) { { min_id: 100, q: subquery } }

    it 'replaces the subquery but preserves the other placeholders' do
      q = 'SELECT * FROM events WHERE id < {min_id:UInt64} AND id IN (SELECT id FROM events WHERE id > {max_id:UInt64})'
      expect(sql).to eq(q)
    end

    it 'replaces the subquery and replaces the placeholders with indexed values' do
      expect(redacted_sql).to eq('SELECT * FROM events WHERE id < $1 AND id IN (SELECT id FROM events WHERE id > $2)')
    end

    it 'merges the placeholders' do
      expect(query.placeholders).to eq({ min_id: 100, max_id: 11 })
    end
  end

  describe 'validation' do
    context 'when SQL string is empty' do
      let(:raw_query) { '' }
      let(:placeholders) { {} }

      it 'raises error' do
        expect { query }.to raise_error(ClickHouse::Client::QueryError, /Empty query string given/)
      end
    end

    context 'when SQL string is nil' do
      let(:raw_query) { nil }
      let(:placeholders) { {} }

      it 'raises error' do
        expect { query }.to raise_error(ClickHouse::Client::QueryError, /Empty query string given/)
      end
    end

    context 'when same placeholder value does not match' do
      let(:raw_query) { 'SELECT id FROM events WHERE id = {id:UInt64} AND id IN ({q:Subquery})' }

      let(:subquery) do
        subquery_string = 'SELECT id FROM events WHERE id = {id:UInt64}'
        described_class.new(raw_query: subquery_string, placeholders: { id: 10 })
      end

      let(:placeholders) { { id: 5, q: subquery } }

      it 'raises error' do
        expect do
          query.placeholders
        end.to raise_error(ClickHouse::Client::QueryError, /mismatching values for the 'id' placeholder/)
      end
    end
  end
end
