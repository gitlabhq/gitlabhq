# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'schema objects assertions for' do |stmt_name|
  let(:stmt) { PgQuery.parse(statement).tree.stmts.first.stmt }
  let(:schema_object) { described_class.new(stmt.public_send(stmt_name)) }

  describe '#name' do
    it 'returns schema object name' do
      expect(schema_object.name).to eq(name)
    end
  end

  describe '#statement' do
    it 'returns schema object statement' do
      expect(schema_object.statement).to eq(statement)
    end
  end

  describe '#table_name' do
    it 'returns schema object table_name' do
      expect(schema_object.table_name).to eq(table_name)
    end
  end
end
