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
    instance_double('connection', class: connection_class, current_schema: 'public')
  end
  # rubocop:enable RSpec/VerifiedDoubleReference

  before do
    allow(connection).to receive(:transaction).and_yield
    allow(connection).to receive(:exec_query)
    allow(connection).to receive(:exec_query).with(/pg_trigger/, nil, anything)
      .and_return(Struct.new(:rows).new(database_triggers))
  end

  let(:database_triggers) do
    [
      ['trigger', 'CREATE TRIGGER trigger AFTER INSERT ON public.t1 FOR EACH ROW EXECUTE FUNCTION t1()'],
      ['wrong_trigger', 'CREATE TRIGGER wrong_trigger BEFORE UPDATE ON public.t2 FOR EACH ROW EXECUTE FUNCTION t2()'],
      ['extra_trigger', 'CREATE TRIGGER extra_trigger BEFORE INSERT ON public.t4 FOR EACH ROW EXECUTE FUNCTION t4()'],
      ['trigger_0123456789ab',
        'CREATE TRIGGER trigger_0123456789ab BEFORE INSERT OR UPDATE ON public.events FOR EACH ROW ' \
          'EXECUTE FUNCTION trigger_0123456789ab()',
        "BEGIN\n  NEW.\"author_id_convert_to_bigint\" := NEW.\"author_id\";\n  RETURN NEW;\nEND;"],
      ['trigger_ba9876543210',
        'CREATE TRIGGER trigger_ba9876543210 BEFORE INSERT OR UPDATE ON public.events FOR EACH ROW ' \
          'EXECUTE FUNCTION trigger_ba9876543210()',
        "BEGIN\n  IF NEW.\"project_id\" IS NULL THEN\n    NEW.\"project_id\" := 1;\n  END IF;\n  RETURN NEW;\nEND;"]
    ]
  end

  it 'returns trigger inconsistencies' do
    expect(result.map(&:object_name)).to match_array(expected_result)
    expect(result.map(&:type)).to all(eql inconsistency_type)
  end
end
