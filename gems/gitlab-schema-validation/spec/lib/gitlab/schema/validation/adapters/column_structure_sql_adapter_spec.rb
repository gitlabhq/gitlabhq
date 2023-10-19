# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Adapters::ColumnStructureSqlAdapter, feature_category: :database do
  subject(:adapter) { described_class.new(table_name, column_def, partition_stmt) }

  let(:table_name) { 'test_table' }
  let(:file_path) { 'spec/fixtures/structure.sql' }
  let(:table_stmts) { PgQuery.parse(File.read(file_path)).tree.stmts.filter_map { |s| s.stmt.create_stmt } }
  let(:table) { table_stmts.find { |table| table.relation.relname == table_name } }
  let(:partition_stmt) { table.partspec }
  let(:column_stmts) { table.table_elts }
  let(:column_def) { column_stmts.find { |col| col.column_def.colname == column_name }.column_def }

  where(:column_name, :data_type, :default_value, :nullable, :partition_key) do
    [
      ['id', 'bigint', nil, 'NOT NULL', false],
      ['integer_column', 'integer', nil, nil, false],
      ['integer_with_default_column', 'integer', 'DEFAULT 1', nil, false],
      ['smallint_with_default_column', 'smallint', 'DEFAULT 0', 'NOT NULL', false],
      ['double_precision_with_default_column', 'double precision', 'DEFAULT 1.0', nil, false],
      ['numeric_with_default_column', 'numeric', 'DEFAULT 1.0', 'NOT NULL', false],
      ['boolean_with_default_column_true', 'boolean', 'DEFAULT true', 'NOT NULL', false],
      ['boolean_with_default_column_false', 'boolean', 'DEFAULT false', 'NOT NULL', false],
      ['varying_with_default_column', 'character varying', "DEFAULT 'DEFAULT'::character varying", 'NOT NULL', false],
      ['varying_with_limit_and_default_column', 'character varying(255)', "DEFAULT 'DEFAULT'::character varying",
        nil, false],
      ['text_with_default_column', 'text', "DEFAULT ''::text", 'NOT NULL', false],
      ['array_with_default_column', 'character varying(255)[]', "DEFAULT '{one,two}'::character varying[]",
        'NOT NULL', false],
      ['jsonb_with_default_column', 'jsonb', "DEFAULT '[]'::jsonb", 'NOT NULL', false],
      ['timestamptz_with_default_column', 'timestamp(6) with time zone', 'DEFAULT now()', nil, false],
      ['timestamp_with_default_column', 'timestamp(6) without time zone',
        "DEFAULT '2022-01-23 00:00:00+00'::timestamp without time zone", 'NOT NULL', false],
      ['date_with_default_column', 'date', 'DEFAULT 2023-04-05', nil, false],
      ['inet_with_default_column', 'inet', "DEFAULT '0.0.0.0'::inet", 'NOT NULL', false],
      ['macaddr_with_default_column', 'macaddr', "DEFAULT '00-00-00-00-00-000'::macaddr", 'NOT NULL', false],
      ['uuid_with_default_column', 'uuid', "DEFAULT '00000000-0000-0000-0000-000000000000'::uuid", 'NOT NULL', false],
      ['partition_key', 'bigint', 'DEFAULT 1', 'NOT NULL', true],
      ['created_at', 'timestamp with time zone', 'DEFAULT now()', 'NOT NULL', true]
    ]
  end

  with_them do
    describe '#name' do
      it { expect(adapter.name).to eq(column_name) }
    end

    describe '#table_name' do
      it { expect(adapter.table_name).to eq(table_name) }
    end

    describe '#data_type' do
      it { expect(adapter.data_type).to eq(data_type) }
    end

    describe '#nullable' do
      it { expect(adapter.nullable).to eq(nullable) }
    end

    describe '#default' do
      it { expect(adapter.default).to eq(default_value) }
    end

    describe '#partition_key?' do
      it { expect(adapter.partition_key?).to eq(partition_key) }
    end
  end

  context 'when the data type is not mapped' do
    let(:column_name) { 'unmapped_column_type' }
    let(:error_class) { Gitlab::Schema::Validation::Adapters::UndefinedPGType }

    describe '#data_type' do
      it { expect { adapter.data_type }.to raise_error(error_class) }
    end
  end
end
