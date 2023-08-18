# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'foreign key validators' do |validator, expected_result|
  subject(:result) { validator.new(structure_file, database).execute }

  let(:structure_file_path) { 'spec/fixtures/structure.sql' }
  let(:structure_file) { Gitlab::Schema::Validation::Sources::StructureSql.new(structure_file_path, schema) }
  let(:inconsistency_type) { validator.to_s }
  let(:database_name) { 'main' }
  let(:schema) { 'public' }
  let(:connection_class) { class_double(Class, name: 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter') }
  # rubocop:disable RSpec/VerifiedDoubleReference
  let(:connection) do
    instance_double('connection', class: connection_class, exec_query: database_query, current_schema: 'public')
  end
  # rubocop:enable RSpec/VerifiedDoubleReference

  let(:database) { Gitlab::Schema::Validation::Sources::Database.new(connection) }

  let(:database_query) do
    [
      {
        'schema' => schema,
        'table_name' => 'web_hooks',
        'foreign_key_name' => 'web_hooks_project_id_fkey',
        'foreign_key_definition' => 'FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE'
      },
      {
        'schema' => schema,
        'table_name' => 'issues',
        'foreign_key_name' => 'wrong_definition_fk',
        'foreign_key_definition' => 'FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE'
      },
      {
        'schema' => schema,
        'table_name' => 'projects',
        'foreign_key_name' => 'extra_fk',
        'foreign_key_definition' => 'FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE CASCADE'
      }
    ]
  end

  it 'returns trigger inconsistencies' do
    expect(result.map(&:object_name)).to match_array(expected_result)
    expect(result.map(&:type)).to all(eql inconsistency_type)
  end
end
