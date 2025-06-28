# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Fixers::Base do
  let(:validator) { Gitlab::Schema::Validation::Validators::MissingIndexes }
  let(:structure_sql_statement) { 'CREATE INDEX index_name ON public.achievements USING btree (id)' }
  let(:structure_stmt) { PgQuery.parse(structure_sql_statement).tree.stmts.first.stmt.index_stmt }
  let(:structure_sql_object) { Gitlab::Schema::Validation::SchemaObjects::Index.new(structure_stmt) }
  let(:inconsistency) { Gitlab::Schema::Validation::Inconsistency.new(validator, structure_sql_object, nil) }

  subject(:fixer) { Gitlab::Schema::Validation::Fixers.create_for(inconsistency) }

  describe '.create_for' do
    context 'when inconsistency type is MissingIndexes' do
      it 'returns a MissingIndex instance' do
        expect(fixer).to be_an_instance_of(Gitlab::Schema::Validation::Fixers::MissingIndex)
      end
    end

    context 'when inconsistency type is not MissingIndexes' do
      let(:validator) { Gitlab::Schema::Validation::Validators::DifferentDefinitionForeignKeys }

      it 'returns a Base instance' do
        expect(fixer).to be_an_instance_of(described_class)
      end

      describe '#statement' do
        it 'returns the structure sql statement' do
          expect(fixer.statement).to eq(structure_sql_statement)
        end
      end
    end
  end
end
