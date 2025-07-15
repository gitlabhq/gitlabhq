# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'sequence validators' do |validator, expected_result|
  let(:structure_file_path) { 'spec/fixtures/structure.sql' }
  let(:inconsistency_type) { validator.name }
  let(:connection_class) { class_double(Class, name: 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter') }
  # rubocop:disable RSpec/VerifiedDoubleReference
  let(:connection) do
    instance_double('connection', class: connection_class, exec_query: database_sequences, current_schema: 'public')
  end
  # rubocop:enable RSpec/VerifiedDoubleReference

  let(:schema) { 'public' }
  let(:database) { Gitlab::Schema::Validation::Sources::Database.new(connection) }
  let(:structure_file) { Gitlab::Schema::Validation::Sources::StructureSql.new(structure_file_path, schema) }
  let(:database_sequences) do
    [
      {
        'sequence_name' => 'wrong_sequence',
        'schema' => schema,
        'user_owner' => 'gitlab',
        'start_value' => '1',
        'increment_by' => '1',
        'min_value' => '1',
        'max_value' => '9223372036854775807',
        'cycle' => 'f',
        'cache_size' => '1',
        'owned_by_column' => 'some_table.id'
      },
      {
        'sequence_name' => 'extra_sequence',
        'schema' => schema,
        'user_owner' => 'gitlab',
        'start_value' => '1',
        'increment_by' => '1',
        'min_value' => '1',
        'max_value' => '9223372036854775807',
        'cycle' => 'f',
        'cache_size' => '1',
        'owned_by_column' => 'extra_table.id'
      },
      {
        'sequence_name' => 'zoekt_repositories_id_seq',
        'schema' => schema,
        'user_owner' => 'gitlab',
        'start_value' => '1',
        'increment_by' => '1',
        'min_value' => '1',
        'max_value' => '9223372036854775807',
        'cycle' => 'f',
        'cache_size' => '1',
        'owned_by_column' => "wrong_table.id"
      },
      {
        'sequence_name' => 'shared_audit_event_id_seq',
        'schema' => schema,
        'user_owner' => 'gitlab',
        'start_value' => '1',
        'increment_by' => '1',
        'min_value' => '1',
        'max_value' => '9223372036854775807',
        'cycle' => 'f',
        'cache_size' => '1',
        'owned_by_column' => nil
      }
    ]
  end

  subject(:result) { validator.new(structure_file, database).execute }

  it 'returns sequence inconsistencies' do
    expect(result.map(&:object_name)).to match_array(expected_result)
    expect(result.map(&:type)).to all(eql inconsistency_type)
  end
end
