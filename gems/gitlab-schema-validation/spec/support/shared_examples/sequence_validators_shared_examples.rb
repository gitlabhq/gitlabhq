# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'sequence validators' do |validator, expected_result|
  let(:structure_file_path) { 'spec/fixtures/structure.sql' }
  let(:database_sequences) do
    %w[
      wrong_sequence
      extra_sequence
      shared_audit_event_id_seq
    ]
  end

  let(:inconsistency_type) { validator.name }
  let(:connection_class) { class_double(Class, name: 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter') }
  # rubocop:disable RSpec/VerifiedDoubleReference
  let(:connection) do
    instance_double('connection', class: connection_class, current_schema: 'public')
  end
  # rubocop:enable RSpec/VerifiedDoubleReference

  let(:schema) { 'public' }
  let(:database) { Gitlab::Schema::Validation::Sources::Database.new(connection) }
  let(:structure_file) { Gitlab::Schema::Validation::Sources::StructureSql.new(structure_file_path, schema) }

  before do
    allow(database).to receive(:sequence_exists?) do |sequence_name|
      database_sequences.include?(sequence_name)
    end
  end

  subject(:result) { validator.new(structure_file, database).execute }

  it 'returns sequence inconsistencies' do
    expect(result.map(&:object_name)).to match_array(expected_result)
    expect(result.map(&:type)).to all(eql inconsistency_type)
  end
end
