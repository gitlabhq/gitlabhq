# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Sources::Database, feature_category: :database do
  subject(:database) { described_class.new(connection) }

  let(:connection_class) { class_double(Class, name: 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter') }
  let(:scs_statement) { 'SET LOCAL standard_conforming_strings TO on' }
  let(:query_result) { Struct.new(:rows).new(index_rows) }

  # rubocop:disable RSpec/VerifiedDoubleReference -- The gem does not depend on ActiveRecord, so the connection class cannot be referenced
  let(:connection) do
    instance_double('connection', class: connection_class, current_schema: 'public')
  end
  # rubocop:enable RSpec/VerifiedDoubleReference

  let(:index_rows) do
    [
      ['shared_name', 'CREATE INDEX shared_name ON gitlab_partitions_static.table_1 USING btree (id)',
        'public', 'index_parent_on_id'],
      ['shared_name', 'CREATE INDEX shared_name ON public.table_1 USING btree (id)', nil, nil]
    ]
  end

  before do
    allow(connection).to receive(:transaction).and_yield
    allow(connection).to receive(:exec_query)
    allow(connection).to receive(:exec_query).with(/pg_indexes/, nil, anything).and_return(query_result)
  end

  describe '#indexes' do
    it 'keeps a public and a partition index with the same name' do
      expect(database.indexes.map(&:statement)).to contain_exactly(
        'CREATE INDEX shared_name ON gitlab_partitions_static.table_1 USING btree (id)',
        'CREATE INDEX shared_name ON public.table_1 USING btree (id)'
      )
    end

    it 'reads the parent index of an attached child' do
      expect(database.indexes.map(&:attachment)).to contain_exactly(
        %w[gitlab_partitions_static table_1 public index_parent_on_id], nil
      )
    end

    it 'reads the catalog with default deparse settings inside a transaction' do
      database.indexes

      expect(connection).to have_received(:transaction).ordered
      expect(connection).to have_received(:exec_query).with("SET LOCAL timezone TO 'UTC'", nil, []).ordered
      expect(connection).to have_received(:exec_query).with(scs_statement, nil, []).ordered
      expect(connection).to have_received(:exec_query).with("SET LOCAL DateStyle TO 'ISO'", nil, []).ordered
      expect(connection).to have_received(:exec_query).with("SET LOCAL IntervalStyle TO 'postgres'", nil, []).ordered
      expect(connection).to have_received(:exec_query)
        .with(/pg_indexes/, nil, %w[gitlab_partitions_static public]).ordered
    end
  end
end
