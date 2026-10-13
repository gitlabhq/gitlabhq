# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::SchemaObjects::Index, feature_category: :database do
  let(:statement) { 'CREATE INDEX index_name ON public.achievements USING btree (namespace_id)' }
  let(:name) { 'index_name' }
  let(:table_name) { 'achievements' }

  include_examples 'schema objects assertions for', 'index_stmt'

  describe '#attachment' do
    let(:parsed_stmt) { PgQuery.parse(statement).tree.stmts.first.stmt.index_stmt }

    it 'is nil for an index without a parent' do
      expect(described_class.new(parsed_stmt).attachment).to be_nil
    end

    it 'returns the table and the parent index of an attached child' do
      index = described_class.new(parsed_stmt, parent: %w[public index_parent_on_namespace_id])

      expect(index.attachment).to eq(%w[public achievements public index_parent_on_namespace_id])
    end
  end

  describe '#definition' do
    subject(:index) { described_class.new(PgQuery.parse(statement).tree.stmts.first.stmt.index_stmt) }

    it 'returns the statement without the index name' do
      expect(index.definition).to eq('CREATE INDEX ON public.achievements USING btree (namespace_id)')
      expect(index.name).to eq(name)
    end
  end
end
