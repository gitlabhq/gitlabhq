# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Fixers::MissingIndex do
  let(:validator) { Gitlab::Schema::Validation::Validators::MissingIndexes }
  let(:structure_sql_statement) { 'CREATE INDEX index_name ON public.achievements USING btree (id)' }
  let(:structure_stmt) { PgQuery.parse(structure_sql_statement).tree.stmts.first.stmt.index_stmt }
  let(:structure_sql_object) { Gitlab::Schema::Validation::SchemaObjects::Index.new(structure_stmt) }
  let(:inconsistency) { Gitlab::Schema::Validation::Inconsistency.new(validator, structure_sql_object, nil) }

  subject(:fixer) { described_class.new(inconsistency) }

  describe '#statement' do
    it 'returns the structure sql statement' do
      expect(fixer.statement).to eq("CREATE INDEX CONCURRENTLY index_name ON public.achievements USING btree (id)")
    end
  end
end
