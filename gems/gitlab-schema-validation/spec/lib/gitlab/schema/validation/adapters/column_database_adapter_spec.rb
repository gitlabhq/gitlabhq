# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Adapters::ColumnDatabaseAdapter, feature_category: :database do
  subject(:adapter) { described_class.new(db_result) }

  let(:column_name) { 'email' }
  let(:column_default) { "'no-reply@gitlab.com'::character varying" }
  let(:not_null) { true }
  let(:partition_key) { false }
  let(:db_result) do
    {
      'table_name' => 'projects',
      'column_name' => column_name,
      'data_type' => 'character varying',
      'column_default' => column_default,
      'not_null' => not_null,
      'partition_key' => partition_key
    }
  end

  describe '#name' do
    it { expect(adapter.name).to eq('email') }
  end

  describe '#table_name' do
    it { expect(adapter.table_name).to eq('projects') }
  end

  describe '#data_type' do
    it { expect(adapter.data_type).to eq('character varying') }
  end

  describe '#default' do
    context "when there's no default value in the column" do
      let(:column_default) { nil }

      it { expect(adapter.default).to be_nil }
    end

    context 'when the column name is id' do
      let(:column_name) { 'id' }

      it { expect(adapter.default).to be_nil }
    end

    context 'when the column default includes nextval' do
      let(:column_default) { "nextval('my_seq'::regclass)" }

      it { expect(adapter.default).to be_nil }
    end

    it { expect(adapter.default).to eq("DEFAULT 'no-reply@gitlab.com'::character varying") }
  end

  describe '#nullable' do
    context 'when column is not null' do
      it { expect(adapter.nullable).to eq('NOT NULL') }
    end

    context 'when column is nullable' do
      let(:not_null) { false }

      it { expect(adapter.nullable).to be_nil }
    end
  end

  describe '#partition_key?' do
    it { expect(adapter.partition_key?).to be(false) }
  end
end
