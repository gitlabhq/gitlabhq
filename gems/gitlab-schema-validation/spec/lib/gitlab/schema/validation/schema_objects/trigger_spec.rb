# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::SchemaObjects::Trigger, feature_category: :database do
  let(:statement) { 'CREATE TRIGGER my_trigger BEFORE INSERT ON todos FOR EACH ROW EXECUTE FUNCTION trigger()' }
  let(:name) { 'my_trigger' }
  let(:table_name) { 'todos' }

  include_examples 'schema objects assertions for', 'create_trig_stmt'

  describe '#function_body' do
    let(:stmt) { PgQuery.parse(statement).tree.stmts.first.stmt.create_trig_stmt }

    it 'is nil when not given' do
      expect(described_class.new(stmt).function_body).to be_nil
    end

    it 'returns the function source read from the database' do
      expect(described_class.new(stmt, function_body: 'BEGIN RETURN NEW; END;').function_body)
        .to eq('BEGIN RETURN NEW; END;')
    end
  end
end
