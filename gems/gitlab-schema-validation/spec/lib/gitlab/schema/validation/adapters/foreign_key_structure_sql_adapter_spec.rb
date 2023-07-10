# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Adapters::ForeignKeyStructureSqlAdapter, feature_category: :database do
  subject(:adapter) { described_class.new(stmt) }

  let(:stmt) { PgQuery.parse(sql).tree.stmts.first.stmt.alter_table_stmt }

  where(:sql, :name, :table_name, :statement) do
    [
      [
        'ALTER TABLE ONLY public.issues ADD CONSTRAINT fk_05f1e72feb FOREIGN KEY (author_id) REFERENCES users (id) ' \
        'ON DELETE SET NULL',
        'public.fk_05f1e72feb',
        'issues',
        'FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE SET NULL'
      ],
      [
        'ALTER TABLE public.import_failures ADD CONSTRAINT fk_9a9b9ba21c FOREIGN KEY (user_id) REFERENCES users(id) ' \
        'ON DELETE CASCADE',
        'public.fk_9a9b9ba21c',
        'import_failures',
        'FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE'
      ]
    ]
  end

  with_them do
    describe '#name' do
      it { expect(adapter.name).to eq(name) }
    end

    describe '#table_name' do
      it { expect(adapter.table_name).to eq(table_name) }
    end

    describe '#statement' do
      it { expect(adapter.statement).to eq(statement) }
    end
  end
end
