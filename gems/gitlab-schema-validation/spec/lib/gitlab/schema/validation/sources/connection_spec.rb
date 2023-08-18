# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Sources::Connection, feature_category: :database do
  let(:sql) { 'SELECT column_one, column_two FROM my_table WHERE schema_name IN ($1);' }
  let(:schemas) { ['public'] }
  let(:query_result) do
    [
      { 'name' => 'Person one', 'email' => 'person.one@gitlab.com' },
      { 'name' => 'Person two', 'email' => 'person.two@gitlab.com' }
    ]
  end

  let(:rows) { query_result.map(&:values) }

  context 'when using active record for postgres adapter' do
    let(:schema) { 'public' }
    let(:connection_class_name) { 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter' }
    let(:adapter_class) { Gitlab::Schema::Validation::Sources::ConnectionAdapters::ActiveRecordAdapter }

    it_behaves_like 'connection adapter'
  end

  context 'when using gitlab active record adapter' do
    let(:schema) { 'gitlab_main' }
    let(:connection_class_name) { 'Gitlab::Database::LoadBalancing::ConnectionProxy' }
    let(:adapter_class) { Gitlab::Schema::Validation::Sources::ConnectionAdapters::ActiveRecordAdapter }

    it_behaves_like 'connection adapter'
  end

  context 'when using postgres adapter' do
    let(:schema) { 'public' }
    let(:connection_class_name) { 'PG::Connection' }
    let(:adapter_class) { Gitlab::Schema::Validation::Sources::ConnectionAdapters::PgAdapter }

    before do
      allow(connection_object).to receive(:exec)
      allow(connection_object).to receive(:type_map_for_results=)
    end

    it_behaves_like 'connection adapter'
  end

  context 'when using an unsupported connection adapter' do
    subject(:connection) { described_class.new(connection_object) }

    let(:connection_class_name) { 'ActiveRecord::ConnectionAdapters::InvalidAdapter' }
    let(:connection_class) { class_double(Class, name: connection_class_name) }
    let(:connection_object) { instance_double(connection_class_name, class: connection_class) }
    let(:error_class) { Gitlab::Schema::Validation::Sources::AdapterNotSupportedError }
    let(:error_message) { 'ActiveRecord::ConnectionAdapters::InvalidAdapter is not supported' }

    it { expect { connection }.to raise_error(error_class, error_message) }
  end
end
