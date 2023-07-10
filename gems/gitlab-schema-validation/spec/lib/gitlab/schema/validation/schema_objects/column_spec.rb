# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::SchemaObjects::Column, feature_category: :database do
  subject(:column) { described_class.new(adapter) }

  let(:database_adapter) { 'Gitlab::Schema::Validation::Adapters::ColumnDatabaseAdapter' }
  let(:adapter) do
    instance_double(database_adapter, name: 'id', table_name: 'projects',
      data_type: 'bigint', default: nil, nullable: 'NOT NULL')
  end

  describe '#name' do
    it { expect(column.name).to eq('id') }
  end

  describe '#table_name' do
    it { expect(column.table_name).to eq('projects') }
  end

  describe '#statement' do
    it { expect(column.statement).to eq('id bigint NOT NULL') }
  end
end
