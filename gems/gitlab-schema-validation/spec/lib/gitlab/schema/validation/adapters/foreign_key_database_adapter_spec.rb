# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Adapters::ForeignKeyDatabaseAdapter, feature_category: :database do
  subject(:adapter) { described_class.new(query_result) }

  let(:query_result) do
    {
      'schema' => 'public',
      'foreign_key_name' => 'fk_2e88fb7ce9',
      'table_name' => 'members',
      'foreign_key_definition' => 'FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE'
    }
  end

  describe '#name' do
    it { expect(adapter.name).to eq('public.fk_2e88fb7ce9') }
  end

  describe '#table_name' do
    it { expect(adapter.table_name).to eq('members') }
  end

  describe '#statement' do
    it { expect(adapter.statement).to eq('FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE') }
  end
end
