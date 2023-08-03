# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'index validators' do |validator, expected_result|
  let(:structure_file_path) { 'spec/fixtures/structure.sql' }
  let(:database_indexes) do
    [
      ['wrong_index', 'CREATE UNIQUE INDEX wrong_index ON public.table_name (column_name)'],
      ['extra_index', 'CREATE INDEX extra_index ON public.table_name (column_name)'],
      ['index', 'CREATE UNIQUE INDEX "index" ON public.achievements USING btree (namespace_id, lower(name))']
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
end
