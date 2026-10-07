# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::PartitionIndexMatcher, feature_category: :database do
  subject(:matcher) { described_class.new(structure_sql, database) }

  let(:structure_sql) { instance_double(Gitlab::Schema::Validation::Sources::StructureSql, indexes: structure_sql_indexes) }
  let(:database) { instance_double(Gitlab::Schema::Validation::Sources::Database, indexes: database_indexes) }

  let(:structure_sql_indexes) do
    [
      parent('index_parent_on_id'),
      parent('index_parent_on_status'),
      index('swapped_1', 'table_1', 'index_parent_on_id'),
      index('swapped_2', 'table_2', 'index_parent_on_id'),
      index('missing', 'table_3', 'index_parent_on_id'),
      index('renamed', 'table_4', 'index_parent_on_id'),
      index('standalone', 'table_1')
    ]
  end

  # The database names swapped_1 and swapped_2 the other way round, missing is not attached, and an unattached
  # index has the old name of renamed.
  let(:database_indexes) do
    [
      parent('index_parent_on_id'),
      parent('index_parent_on_status'),
      index('swapped_2', 'table_1', 'index_parent_on_id'),
      index('swapped_1', 'table_2', 'index_parent_on_id'),
      index('extra', 'table_3', 'index_parent_on_status'),
      index('missing', 'table_3'),
      index('renamed_new', 'table_4', 'index_parent_on_id'),
      index('renamed', 'table_4'),
      index('standalone', 'table_1')
    ]
  end

  def parent(name)
    build("CREATE INDEX #{name} ON ONLY public.parent_table USING btree (id)")
  end

  def index(name, table, parent = nil)
    build("CREATE INDEX #{name} ON gitlab_partitions_static.#{table} USING btree (id)", (['public', parent] if parent))
  end

  def build(statement, parent = nil)
    parsed_stmt = PgQuery.parse(statement).tree.stmts.first.stmt.index_stmt

    Gitlab::Schema::Validation::SchemaObjects::Index.new(parsed_stmt, parent: parent)
  end

  def names(indexes, predicate)
    indexes.select { |index| matcher.public_send(predicate, index) }.map(&:name)
  end

  it 'pairs children by table and parent index, whatever their names' do
    counterparts = structure_sql_indexes.select(&:attachment).to_h do |index|
      [index.name, matcher.counterpart(index)&.name]
    end

    expect(counterparts).to eq(
      'swapped_1' => 'swapped_2', 'swapped_2' => 'swapped_1', 'missing' => nil, 'renamed' => 'renamed_new'
    )
  end

  it 'reports a structure.sql child without an attached database counterpart as missing' do
    expect(names(structure_sql_indexes, :missing?)).to eq(['missing'])
  end

  it 'reports an unpaired database index as extra, also when a paired structure.sql child has its name' do
    expect(names(database_indexes, :extra?)).to eq(%w[extra renamed])
  end

  context 'when the parent index has another name in the database' do
    let(:structure_sql_indexes) { [parent('index_parent_on_id'), index('child', 'table_1', 'index_parent_on_id')] }
    let(:database_indexes) { [parent('index_renamed'), index('child', 'table_1', 'index_renamed')] }

    it 'reports only the parent indexes' do
      expect([names(structure_sql_indexes, :missing?), names(database_indexes, :extra?)])
        .to eq([['index_parent_on_id'], ['index_renamed']])
    end
  end
end
