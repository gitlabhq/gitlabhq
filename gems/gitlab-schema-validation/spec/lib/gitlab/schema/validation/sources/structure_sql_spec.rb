# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'structure sql schema assertions for' do |object_exists_method, all_objects_method|
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
      %w[missing_index wrong_index index index_namespaces_public_groups_name_id
        index_on_deploy_keys_id_and_type_and_public index_users_on_public_email_excluding_null_and_empty]
    end

    include_examples 'structure sql schema assertions for', 'index_exists?', 'indexes'
  end

  context 'when having triggers' do
    let(:schema_object) { Gitlab::Schema::Validation::SchemaObjects::Trigger }
    let(:valid_schema_object_name) { 'trigger' }
    let(:expected_objects) { %w[trigger wrong_trigger missing_trigger_1 projects_loose_fk_trigger] }

    include_examples 'structure sql schema assertions for', 'trigger_exists?', 'triggers'
  end

  context 'when having tables' do
    let(:schema_object) { Gitlab::Schema::Validation::SchemaObjects::Table }
    let(:valid_schema_object_name) { 'test_table' }
    let(:expected_objects) do
      %w[test_table ci_project_mirrors wrong_table extra_table_columns missing_table missing_table_columns
        operations_user_lists]
    end

    include_examples 'structure sql schema assertions for', 'table_exists?', 'tables'
  end
end
