# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'structure sql schema assertions for' do |object_exists_method, all_objects_method,
                                                                fetch_object_method|
  subject(:structure_sql) { described_class.new(structure_file_path, schema_name) }

  let(:structure_file_path) { 'spec/fixtures/structure.sql' }
  let(:schema_name) { 'public' }

  describe "##{object_exists_method}" do
    it 'returns true when schema object exists' do
      expect(structure_sql.public_send(object_exists_method, valid_schema_object_name)).to be_truthy
    end

    it 'returns false when schema object does not exists' do
      expect(structure_sql.public_send(object_exists_method, 'invalid-object-name')).to be_falsey
    end

    it 'fetch fetches the schema object' do
      expect(structure_sql.public_send(fetch_object_method,
        valid_schema_object_name)).to be_an_instance_of(schema_object)
    end
  end

  describe "##{all_objects_method}" do
    it 'returns all the schema objects' do
      schema_objects = structure_sql.public_send(all_objects_method)

      expect(schema_objects).to all(be_a(schema_object))
      expect(schema_objects.map(&:name)).to eq(expected_objects)
    end
  end
end

RSpec.describe Gitlab::Schema::Validation::Sources::StructureSql, feature_category: :database do
  let(:structure_file_path) { 'spec/fixtures/structure.sql' }
  let(:schema_name) { 'public' }

  subject(:structure_sql) { described_class.new(structure_file_path, schema_name) }

  context 'when having indexes' do
    let(:schema_object) { Gitlab::Schema::Validation::SchemaObjects::Index }
    let(:valid_schema_object_name) { 'index' }
    let(:expected_objects) do
      %w[missing_index wrong_index renamed_index duplicated_index swapped_index_1 swapped_index_2 index
        index_namespaces_public_groups_name_id index_partitioned_table_on_id index_partitioned_table_on_column_name
        index_other_partitioned_table_on_column_name index_partitioned_table_on_column_name_2
        index_partitioned_table_on_created_at index_partitioned_table_on_other_column
        index_public_partitioned_table_on_id partition_index partition_index_1 partition_index_2
        renamed_partition_index wrong_partition_index redefined_partition_index missing_partition_index
        detached_partition_index relocated_partition_index standalone_partition_index public_partition_index_1
        public_partition_index_2 index_on_deploy_keys_id_and_type_and_public
        index_users_on_public_email_excluding_null_and_empty]
    end

    include_examples 'structure sql schema assertions for', 'index_exists?', 'indexes', 'fetch_index_by_name'

    it 'reads the parent index of attached children' do
      attachments = structure_sql.indexes.to_h { |index| [index.name, index.attachment] }

      expect(attachments).to include(
        'partition_index' => %w[gitlab_partitions_static partitioned_table_1 public index_partitioned_table_on_id],
        'public_partition_index_1' => %w[public public_partitioned_table_1 public index_public_partitioned_table_on_id],
        'standalone_partition_index' => nil,
        'missing_index' => nil
      )
    end
  end

  context 'when having triggers' do
    let(:schema_object) { Gitlab::Schema::Validation::SchemaObjects::Trigger }
    let(:valid_schema_object_name) { 'trigger' }
    let(:expected_objects) { %w[trigger wrong_trigger missing_trigger_1 projects_loose_fk_trigger] }

    include_examples 'structure sql schema assertions for', 'trigger_exists?', 'triggers', 'fetch_trigger_by_name'
  end

  context 'when having tables' do
    let(:schema_object) { Gitlab::Schema::Validation::SchemaObjects::Table }
    let(:valid_schema_object_name) { 'test_table' }
    let(:expected_objects) do
      %w[test_table ci_project_mirrors wrong_table extra_table_columns missing_table missing_table_columns
        operations_user_lists]
    end

    include_examples 'structure sql schema assertions for', 'table_exists?', 'tables', 'fetch_table_by_name'
  end
end
