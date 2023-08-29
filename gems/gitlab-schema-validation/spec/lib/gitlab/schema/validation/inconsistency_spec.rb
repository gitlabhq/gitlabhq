# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Inconsistency, feature_category: :database do
  let(:validator) { Gitlab::Schema::Validation::Validators::DifferentDefinitionIndexes }

  let(:database_statement) { 'CREATE INDEX index_name ON public.achievements USING btree (namespace_id)' }
  let(:structure_sql_statement) { 'CREATE INDEX index_name ON public.achievements USING btree (id)' }

  let(:structure_stmt) { PgQuery.parse(structure_sql_statement).tree.stmts.first.stmt.index_stmt }
  let(:database_stmt) { PgQuery.parse(database_statement).tree.stmts.first.stmt.index_stmt }

  let(:structure_sql_object) { Gitlab::Schema::Validation::SchemaObjects::Index.new(structure_stmt) }
  let(:database_object) { Gitlab::Schema::Validation::SchemaObjects::Index.new(database_stmt) }

  subject(:inconsistency) { described_class.new(validator, structure_sql_object, database_object) }

  describe '#object_name' do
    it 'returns the index name' do
      expect(inconsistency.object_name).to eq('index_name')
    end
  end

  describe '#diff' do
    it 'returns a diff between the structure.sql and the database' do
      expect(inconsistency.diff).to be_a(Diffy::Diff)
      expect(inconsistency.diff.string1).to eq("#{structure_sql_statement}\n")
      expect(inconsistency.diff.string2).to eq("#{database_statement}\n")
    end
  end

  describe '#error_message' do
    it 'returns the error message' do
      stub_const "#{validator}::ERROR_MESSAGE", 'error message %s'

      expect(inconsistency.error_message).to eq('error message index_name')
    end
  end

  describe '#type' do
    it 'returns the type of the validator' do
      expect(inconsistency.type).to eq('Gitlab::Schema::Validation::Validators::DifferentDefinitionIndexes')
    end
  end

  describe '#to_h' do
    let(:result) do
      {
        database_statement: inconsistency.database_statement,
        object_name: inconsistency.object_name,
        object_type: inconsistency.object_type,
        structure_sql_statement: inconsistency.structure_sql_statement,
        table_name: inconsistency.table_name,
        type: inconsistency.type
      }
    end

    it 'returns the to_h of the validator' do
      expect(inconsistency.to_h).to eq(result)
    end
  end

  describe '#table_name' do
    it 'returns the table name' do
      expect(inconsistency.table_name).to eq('achievements')
    end
  end

  describe '#object_type' do
    it 'returns the structure sql object type' do
      expect(inconsistency.object_type).to eq('Index')
    end

    context 'when the structure sql object is not available' do
      subject(:inconsistency) { described_class.new(validator, nil, database_object) }

      it 'returns the database object type' do
        expect(inconsistency.object_type).to eq('Index')
      end
    end
  end

  describe '#structure_sql_statement' do
    it 'returns structure sql statement' do
      expect(inconsistency.structure_sql_statement).to eq("#{structure_sql_statement}\n")
    end
  end

  describe '#database_statement' do
    it 'returns database statement' do
      expect(inconsistency.database_statement).to eq("#{database_statement}\n")
    end
  end

  describe '#display' do
    let(:expected_output) do
      <<~MSG
        ------------------------------------------------------
        The index_name index has a different statement between structure.sql and database
        Diff:
        \e[31m-CREATE INDEX index_name ON public.achievements USING btree (id)\e[0m
        \e[32m+CREATE INDEX index_name ON public.achievements USING btree (namespace_id)\e[0m

        ------------------------------------------------------
      MSG
    end

    it 'prints the inconsistency message' do
      expect(inconsistency.display).to eql(expected_output)
    end
  end
end
