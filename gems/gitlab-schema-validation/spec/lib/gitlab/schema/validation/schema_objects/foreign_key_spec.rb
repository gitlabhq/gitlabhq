# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::SchemaObjects::ForeignKey, feature_category: :database do
  subject(:foreign_key) { described_class.new(adapter) }

  let(:database_adapter) { 'Gitlab::Schema::Validation::Adapters::ForeignKeyDatabaseAdapter' }
  let(:adapter) do
    instance_double(database_adapter, name: 'public.fk_1d37cddf91', table_name: 'vulnerabilities',
      statement: 'FOREIGN KEY (epic_id) REFERENCES epics(id) ON DELETE SET NULL')
  end

  describe '#name' do
    it { expect(foreign_key.name).to eq('public.fk_1d37cddf91') }
  end

  describe '#table_name' do
    it { expect(foreign_key.table_name).to eq('vulnerabilities') }
  end

  describe '#statement' do
    it { expect(foreign_key.statement).to eq('FOREIGN KEY (epic_id) REFERENCES epics(id) ON DELETE SET NULL') }
  end
end
