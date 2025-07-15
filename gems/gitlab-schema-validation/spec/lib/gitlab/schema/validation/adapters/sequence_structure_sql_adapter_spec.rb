# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Adapters::SequenceStructureSqlAdapter do
  let(:sequence_name) { 'users_id_seq' }
  let(:schema_name) { 'public' }
  let(:owner_table) { 'users' }
  let(:owner_column) { 'id' }
  let(:owner_schema) { 'app_schema' }

  subject(:sequence_sql_adapter) do
    described_class.new(
      sequence_name: sequence_name,
      schema_name: schema_name,
      owner_table: owner_table,
      owner_column: owner_column,
      owner_schema: owner_schema
    )
  end

  describe '#initialize' do
    context 'with all parameters' do
      it 'sets all attributes correctly' do
        expect(sequence_sql_adapter.sequence_name).to eq(sequence_name)
        expect(sequence_sql_adapter.schema_name).to eq(schema_name)
        expect(sequence_sql_adapter.owner_table).to eq(owner_table)
        expect(sequence_sql_adapter.owner_column).to eq(owner_column)
        expect(sequence_sql_adapter.owner_schema).to eq(owner_schema)
      end
    end

    context 'with minimal parameters' do
      let(:schema_name) { nil }
      let(:owner_table) { nil }
      let(:owner_column) { nil }
      let(:owner_schema) { nil }

      it 'sets sequence_name and defaults others to nil' do
        expect(sequence_sql_adapter.sequence_name).to eq(sequence_name)
        expect(sequence_sql_adapter.schema_name).to be_nil
        expect(sequence_sql_adapter.owner_table).to be_nil
        expect(sequence_sql_adapter.owner_column).to be_nil
        expect(sequence_sql_adapter.owner_schema).to be_nil
      end
    end
  end

  describe '#name' do
    context 'when schema_name is present' do
      let(:owner_table) { nil }
      let(:owner_column) { nil }
      let(:owner_schema) { nil }

      it 'returns fully qualified sequence name' do
        expect(sequence_sql_adapter.name).to eq('public.users_id_seq')
      end
    end

    context 'when schema_name and owner_schema are nil' do
      let(:schema_name) { nil }
      let(:owner_schema) { nil }

      it 'returns sequence name with public schema' do
        expect(sequence_sql_adapter.name).to eq('public.users_id_seq')
      end
    end
  end

  describe '#column_name' do
    it 'returns the owner_column' do
      expect(sequence_sql_adapter.column_name).to eq(owner_column)
    end
  end

  describe '#table_name' do
    it 'returns the owner_table' do
      expect(sequence_sql_adapter.table_name).to eq(owner_table)
    end
  end

  describe '#column_owner' do
    context 'when owner_schema, owner_table, and owner_column are all present' do
      it 'returns fully qualified column reference' do
        expect(sequence_sql_adapter.column_owner).to eq('app_schema.users.id')
      end
    end

    context 'when only owner_table and owner_column are present' do
      let(:sequence_name) { nil }
      let(:schema_name) { nil }
      let(:owner_schema) { nil }

      it 'returns table.column format' do
        expect(sequence_sql_adapter.column_owner).to eq('public.users.id')
      end
    end

    context 'when only owner_column is present' do
      let(:owner_table) { nil }

      it 'returns nil' do
        expect(sequence_sql_adapter.column_owner).to be_nil
      end
    end

    context 'when no owner information is present' do
      let(:owner_table) { nil }
      let(:owner_column) { nil }

      it 'returns nil' do
        expect(sequence_sql_adapter.column_owner).to be_nil
      end
    end
  end

  describe '#schema' do
    context 'when schema_name is present' do
      it 'returns schema_name' do
        expect(sequence_sql_adapter.schema).to eq(schema_name)
      end
    end

    context 'when schema_name is nil but owner_schema is present' do
      let(:schema_name) { nil }

      it 'returns owner_schema' do
        expect(sequence_sql_adapter.schema).to eq(owner_schema)
      end
    end

    context 'when both schema_name and owner_schema are nil' do
      let(:schema_name) { nil }
      let(:owner_schema) { nil }

      it 'returns default public schema' do
        expect(sequence_sql_adapter.schema).to eq('public')
      end
    end

    context 'when schema_name is present and owner_schema is also present' do
      it 'prioritizes schema_name over owner_schema' do
        expect(sequence_sql_adapter.schema).to eq(schema_name)
      end
    end
  end

  describe '#to_s' do
    it 'returns a string representation' do
      expect(sequence_sql_adapter.to_s).to eq('SequenceStructureSqlAdapter(public.users_id_seq -> app_schema.users.id)')
    end
  end

  describe '#inspect' do
    it 'returns an inspect string with object_id' do
      result = sequence_sql_adapter.inspect
      expect(result).to match(/^#<SequenceStructureSqlAdapter:\d+ public\.users_id_seq -> app_schema\.users\.id>$/)
    end
  end
end
