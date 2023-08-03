# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'trigger validators' do |validator, expected_result|
  subject(:result) { validator.new(structure_file, database).execute }

  let(:structure_file_path) { 'spec/fixtures/structure.sql' }
  let(:structure_file) { Gitlab::Schema::Validation::Sources::StructureSql.new(structure_file_path, schema) }
  let(:inconsistency_type) { validator.to_s }
  let(:database_name) { 'main' }
  let(:schema) { 'public' }
  let(:database) { Gitlab::Schema::Validation::Sources::Database.new(connection) }
  let(:connection_class) { class_double(Class, name: 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter') }

  # rubocop:disable RSpec/VerifiedDoubleReference
  let(:connection) do
    instance_double('connection', class: connection_class, select_rows: database_triggers, current_schema: 'public')
  end
  # rubocop:enable RSpec/VerifiedDoubleReference

  let(:database_triggers) do
    [
      ['trigger', 'CREATE TRIGGER trigger AFTER INSERT ON public.t1 FOR EACH ROW EXECUTE FUNCTION t1()'],
      ['wrong_trigger', 'CREATE TRIGGER wrong_trigger BEFORE UPDATE ON public.t2 FOR EACH ROW EXECUTE FUNCTION t2()'],
      ['extra_trigger', 'CREATE TRIGGER extra_trigger BEFORE INSERT ON public.t4 FOR EACH ROW EXECUTE FUNCTION t4()']
    ]
  end

  it 'returns trigger inconsistencies' do
    expect(result.map(&:object_name)).to match_array(expected_result)
    expect(result.map(&:type)).to all(eql inconsistency_type)
  end
end
