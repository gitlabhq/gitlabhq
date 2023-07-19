# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::SchemaObjects::Table, feature_category: :database do
  subject(:table) { described_class.new(name, columns) }

  let(:name) { 'my_table' }
  let(:column_class) { 'Gitlab::Schema::Validation::SchemaObjects::Column' }
  let(:columns) do
    [
      instance_double(column_class, name: 'id', statement: 'id bigint NOT NULL', partition_key?: false),
      instance_double(column_class, name: 'col', statement: 'col text', partition_key?: false),
      instance_double(column_class, name: 'partition', statement: 'partition integer DEFAULT 1', partition_key?: true)
    ]
  end

  describe '#name' do
    it { expect(table.name).to eq('my_table') }
  end

  describe '#table_name' do
    it { expect(table.table_name).to eq('my_table') }
  end

  describe '#statement' do
    it { expect(table.statement).to eq('CREATE TABLE my_table (id bigint NOT NULL, col text)') }

    it 'ignores the partition column' do
      expect(table.statement).not_to include('partition integer DEFAULT 1')
    end
  end

  describe '#fetch_column_by_name' do
    it { expect(table.fetch_column_by_name('col')).not_to be_nil }

    it { expect(table.fetch_column_by_name('invalid')).to be_nil }
  end

  describe '#column_exists?' do
    it { expect(table.column_exists?('col')).to be(true) }

    it { expect(table.column_exists?('invalid')).to be(false) }
  end
end
