# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Sources::Database, feature_category: :database do
  subject(:database) { described_class.new(connection) }

  let(:connection_class) { class_double(Class, name: 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter') }

  # rubocop:disable RSpec/VerifiedDoubleReference -- The gem does not depend on ActiveRecord, so the connection class cannot be referenced
  let(:connection) do
    instance_double('connection', class: connection_class, select_rows: index_rows, current_schema: 'public')
  end
  # rubocop:enable RSpec/VerifiedDoubleReference

  let(:index_rows) do
    [
      ['shared_name', 'CREATE INDEX shared_name ON gitlab_partitions_static.table_1 USING btree (id)',
        'public', 'index_parent_on_id'],
      ['shared_name', 'CREATE INDEX shared_name ON public.table_1 USING btree (id)', nil, nil]
    ]
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
  end
end
