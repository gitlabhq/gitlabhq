# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'index validators' do |validator, expected_result|
  let(:structure_file_path) { 'spec/fixtures/structure.sql' }
  let(:database_indexes) do
    [
      ['wrong_index', 'CREATE UNIQUE INDEX wrong_index ON public.table_name (column_name)'],
      ['extra_index', 'CREATE INDEX extra_index ON public.table_name (column_name)'],
      ['index', 'CREATE UNIQUE INDEX "index" ON public.achievements USING btree (namespace_id, lower(name))'],
      ['renamed_index_new', 'CREATE INDEX renamed_index_new ON public.events USING btree (id)'],
      ['duplicated_index_copy', 'CREATE INDEX duplicated_index_copy ON public.events USING btree (project_id)'],
      ['duplicated_index', 'CREATE INDEX duplicated_index ON public.events USING btree (project_id)'],
      ['swapped_index_1', 'CREATE INDEX swapped_index_1 ON public.events USING btree (target_type)'],
      ['swapped_index_2', 'CREATE INDEX swapped_index_2 ON public.events USING btree (target_id)'],
      ['index_partitioned_table_on_id',
        'CREATE INDEX index_partitioned_table_on_id ON ONLY public.partitioned_table USING btree (id)'],
      ['index_partitioned_table_on_column_name',
        'CREATE INDEX index_partitioned_table_on_column_name ON ONLY public.partitioned_table ' \
          'USING btree (column_name)'],
      ['index_other_partitioned_table_on_column_name',
        'CREATE INDEX index_other_partitioned_table_on_column_name ON ONLY public.other_partitioned_table ' \
          'USING btree (column_name) WHERE (status = 0)'],
      ['index_partitioned_table_on_column_name_2',
        'CREATE INDEX index_partitioned_table_on_column_name_2 ON ONLY public.partitioned_table ' \
          'USING btree (column_name_2)'],
      ['index_partitioned_table_on_created_at',
        'CREATE INDEX index_partitioned_table_on_created_at ON ONLY public.partitioned_table USING btree (created_at)'],
      ['index_partitioned_table_on_other_column',
        'CREATE INDEX index_partitioned_table_on_other_column ON ONLY public.partitioned_table ' \
          'USING btree (other_column)'],
      ['index_public_partitioned_table_on_id',
        'CREATE INDEX index_public_partitioned_table_on_id ON ONLY public.public_partitioned_table USING btree (id)'],
      ['renamed_partition_index',
        'CREATE INDEX renamed_partition_index ON gitlab_partitions_static.partitioned_table_3 ' \
          'USING btree (created_at)'],
      ['partition_index',
        'CREATE INDEX partition_index ON gitlab_partitions_static.partitioned_table_1 USING btree (id)',
        'public', 'index_partitioned_table_on_id'],
      ['partition_index_1',
        'CREATE INDEX partition_index_1 ON gitlab_partitions_static.other_partitioned_table_1 ' \
          'USING btree (column_name) WHERE (status = 0)',
        'public', 'index_other_partitioned_table_on_column_name'],
      ['partition_index_2',
        'CREATE INDEX partition_index_2 ON gitlab_partitions_static.partitioned_table_1 USING btree (column_name)',
        'public', 'index_partitioned_table_on_column_name'],
      ['renamed_partition_index_new',
        'CREATE INDEX renamed_partition_index_new ON gitlab_partitions_static.partitioned_table_3 USING btree (id)',
        'public', 'index_partitioned_table_on_id'],
      ['wrong_partition_index',
        'CREATE INDEX wrong_partition_index ON gitlab_partitions_static.partitioned_table_1 ' \
          'USING btree (column_name_3)',
        'public', 'index_partitioned_table_on_column_name_2'],
      ['redefined_partition_index_new',
        'CREATE INDEX redefined_partition_index_new ON gitlab_partitions_static.partitioned_table_7 ' \
          'USING btree (created_at, id)',
        'public', 'index_partitioned_table_on_created_at'],
      ['detached_partition_index',
        'CREATE INDEX detached_partition_index ON gitlab_partitions_static.partitioned_table_6 USING btree (id)'],
      ['relocated_partition_index',
        'CREATE INDEX relocated_partition_index ON gitlab_partitions_static.partitioned_table_9 USING btree (id)',
        'public', 'index_partitioned_table_on_id'],
      ['standalone_partition_index',
        'CREATE INDEX standalone_partition_index ON gitlab_partitions_static.partitioned_table_5 USING btree (id)'],
      ['extra_partition_index',
        'CREATE INDEX extra_partition_index ON gitlab_partitions_static.partitioned_table_2 ' \
          'USING btree (other_column)',
        'public', 'index_partitioned_table_on_other_column'],
      ['manual_partition_index',
        'CREATE INDEX manual_partition_index ON gitlab_partitions_static.partitioned_table_4 USING btree (id)'],
      ['public_partition_index_1',
        'CREATE INDEX public_partition_index_1 ON public.public_partitioned_table_2 USING btree (id)',
        'public', 'index_public_partitioned_table_on_id'],
      ['bigint_idx_0123456789abcdef0123',
        'CREATE INDEX bigint_idx_0123456789abcdef0123 ON public.events USING btree (author_id_convert_to_bigint)'],
      ['bigint_idx_manual', 'CREATE INDEX bigint_idx_manual ON public.events USING btree (author_id)'],
      ['unique_schema_migrations',
        'CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version)'],
      ['public_partition_index_2',
        'CREATE INDEX public_partition_index_2 ON public.public_partitioned_table_1 USING btree (id)',
        'public', 'index_public_partitioned_table_on_id']
    ]
  end

  let(:inconsistency_type) { validator.name }
  let(:connection_class) { class_double(Class, name: 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter') }

  # rubocop:disable RSpec/VerifiedDoubleReference
  let(:connection) do
    instance_double('connection', class: connection_class, select_rows: database_indexes, current_schema: 'public')
  end
  # rubocop:enable RSpec/VerifiedDoubleReference

  let(:schema) { 'public' }

  let(:database) { Gitlab::Schema::Validation::Sources::Database.new(connection) }
  let(:structure_file) { Gitlab::Schema::Validation::Sources::StructureSql.new(structure_file_path, schema) }

  subject(:result) { validator.new(structure_file, database).execute }

  it 'returns index inconsistencies' do
    expect(result.map(&:object_name)).to match_array(expected_result)
    expect(result.map(&:type)).to all(eql inconsistency_type)
  end

  it 'builds the partition index matcher once' do
    expect(Gitlab::Schema::Validation::Validators::PartitionIndexMatcher).to receive(:new).once.and_call_original

    result
  end
end
