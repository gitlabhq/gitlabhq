# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Postgresql::Client do
  let(:options) do
    {
      host: 'localhost',
      port: 5432,
      database: 'test_db',
      user: 'user',
      password: 'pass',
      pool_size: 2,
      pool_timeout: 1
    }
  end

  let(:connection_pool) { instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool) }
  let(:connection_model) { class_double(ActiveRecord::Base) }
  let(:ar_connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
  let(:raw_connection) { instance_double(PG::Connection) }

  subject(:client) { described_class.new(options) }

  before do
    allow_any_instance_of(described_class).to receive(:create_connection_model).and_return(connection_model)
    allow(connection_model).to receive(:establish_connection)
    allow(connection_model).to receive(:connection_pool).and_return(connection_pool)
  end

  describe '#initialize' do
    it 'sets options with indifferent access' do
      expect(client.options).to be_a(ActiveSupport::HashWithIndifferentAccess)
      expect(client.options[:host]).to eq('localhost')
      expect(client.options['host']).to eq('localhost')
    end

    it 'establishes a connection pool' do
      expect(client.connection_pool).to eq(connection_pool)
    end
  end

  describe '#with_raw_connection' do
    before do
      allow(connection_pool).to receive(:with_connection).and_yield(ar_connection)
      allow(ar_connection).to receive(:raw_connection).and_return(raw_connection)
    end

    it 'provides raw PostgreSQL connection for operations' do
      result = client.with_raw_connection(&:object_id)

      expect(result).to eq(raw_connection.object_id)
    end

    context 'when a PG error occurs' do
      before do
        allow(raw_connection).to receive(:exec).and_raise(PG::Error.new('query failed'))
        allow(ActiveContext::Logger).to receive(:exception)
      end

      it 'logs and re-raises the error' do
        expect(ActiveContext::Logger).to receive(:exception).with(an_instance_of(PG::Error),
          class: described_class.name, message: 'Database error occurred')

        expect do
          client.with_raw_connection { |conn| conn.exec('SELECT 1') }
        end.to raise_error(PG::Error, 'query failed')
      end
    end
  end

  describe '#with_connection' do
    before do
      allow(connection_pool).to receive(:with_connection).and_yield(ar_connection)
    end

    it 'provides ActiveRecord connection for operations' do
      result = client.with_connection(&:object_id)

      expect(result).to eq(ar_connection.object_id)
    end

    context 'when database error occurs' do
      before do
        allow(ActiveContext::Logger).to receive(:exception)
      end

      it 'logs and re-raises PG::Error' do
        expect(ActiveContext::Logger).to receive(:exception).with(an_instance_of(PG::Error),
          class: described_class.name, message: 'Database error occurred')

        expect do
          client.with_connection { raise PG::Error, 'query failed' }
        end.to raise_error(PG::Error, 'query failed')
      end

      it 'logs and re-raises ActiveRecord::StatementInvalid' do
        expect(ActiveContext::Logger).to receive(:exception).with(an_instance_of(ActiveRecord::StatementInvalid),
          class: described_class.name, message: 'Database error occurred')

        expect do
          client.with_connection { raise ActiveRecord::StatementInvalid, 'invalid SQL' }
        end.to raise_error(ActiveRecord::StatementInvalid, 'invalid SQL')
      end
    end
  end

  describe '#search' do
    let(:query_result) { instance_double(PG::Result) }
    let(:processed_result) { instance_double(ActiveContext::Databases::Postgresql::QueryResult) }
    let(:collection) { double }
    let(:user) { double }
    let(:authorized_results) { [{ 'id' => 1 }] }

    before do
      allow(connection_pool).to receive(:with_connection).and_yield(ar_connection)
      allow(ar_connection).to receive(:execute).and_return(query_result)
      allow(ActiveContext::Databases::Postgresql::QueryResult).to receive(:new).and_return(processed_result)
      allow(processed_result).to receive(:authorized_results).and_return(authorized_results)
    end

    it 'executes query and returns authorized results' do
      expect(ActiveContext::Databases::Postgresql::Processor)
        .to receive(:transform).with(collection: collection, node: anything, user: user)
        .and_return('SELECT * FROM pg_stat_activity')
      expect(ar_connection).to receive(:execute).with('SELECT * FROM pg_stat_activity')
      expect(ActiveContext::Databases::Postgresql::QueryResult)
        .to receive(:new).with(result: query_result, collection: collection, user: user)

      result = client.search(collection: collection, query: ActiveContext::Query.filter(project_id: 1), user: user)

      expect(result).to eq(authorized_results)
    end
  end

  describe '#bulk_process' do
    let(:model_class) { class_double(ActiveRecord::Base) }

    before do
      allow(connection_pool).to receive(:with_connection).and_yield(ar_connection)
      allow(ar_connection).to receive(:pool).and_return(connection_pool)
    end

    context 'with empty operations' do
      it 'returns an empty array' do
        result = client.bulk_process([])

        expect(result).to eq([])
      end
    end

    context 'with upsert operations' do
      let(:collection_name) { 'test_collection' }
      let(:operations) do
        [
          { collection_name => { upsert: { id: 1, partition_id: 1, data: 'test' } }, ref: 'ref1' }
        ]
      end

      before do
        allow(model_class).to receive(:transaction).and_yield
        allow(model_class).to receive(:upsert_all).and_return(true)
      end

      it 'processes upsert operations through the model' do
        expect(client).to receive(:with_model_for).with(collection_name).and_yield(model_class)
        expect(model_class).to receive(:upsert_all).with(
          [{ id: 1, partition_id: 1, data: 'test' }],
          unique_by: [:id, :partition_id],
          update_only: [:data]
        )

        result = client.bulk_process(operations)

        expect(result).to eq([])
      end

      context 'when an error occurs' do
        before do
          allow(client).to receive(:with_model_for).and_yield(model_class)
          allow(model_class).to receive(:transaction).and_raise(StandardError.new('upsert failed'))
          allow(ActiveContext::Logger).to receive(:exception)
        end

        it 'logs the error and returns failed operation refs' do
          result = client.bulk_process(operations)

          expect(ActiveContext::Logger).to have_received(:exception).with(an_instance_of(StandardError),
            class: described_class.name, message: "Error with upsert operation for #{collection_name}")
          expect(result).to eq(['ref1'])
        end
      end
    end

    context 'with delete operations' do
      let(:collection_name) { 'test_collection' }
      let(:operations) do
        [
          { collection_name => { delete: { ref_id: 1 } }, ref: 'ref1' }
        ]
      end

      before do
        allow(model_class).to receive(:where).with(ref_id: [1]).and_return(model_class)
        allow(model_class).to receive(:delete_all).and_return(1)
      end

      it 'processes delete operations through the model' do
        expect(client).to receive(:with_model_for).with(collection_name).and_yield(model_class)
        expect(model_class).to receive(:where).with(ref_id: [1])
        expect(model_class).to receive(:delete_all)

        result = client.bulk_process(operations)

        expect(result).to eq([])
      end

      context 'with ref_version filtering' do
        before do
          query = double(where: double(not: model_class), delete_all: nil)
          allow(model_class).to receive(:where).and_return(query)
        end

        it 'excludes records matching ref_version from deletion' do
          operations = [
            { collection_name => { delete: { ref_id: 1, ref_version: 2 } }, ref: 'ref1' },
            { collection_name => { delete: { ref_id: 2, ref_version: 2 } }, ref: 'ref2' }
          ]

          expect(client).to receive(:with_model_for).with(collection_name).and_yield(model_class)

          result = client.bulk_process(operations)

          expect(result).to eq([])
        end
      end

      context 'when an error occurs' do
        before do
          allow(client).to receive(:with_model_for).and_yield(model_class)
          allow(model_class).to receive(:where).and_raise(StandardError.new('delete failed'))
          allow(ActiveContext::Logger).to receive(:exception)
        end

        it 'logs the error and returns failed operation refs' do
          result = client.bulk_process(operations)

          expect(ActiveContext::Logger).to have_received(:exception).with(an_instance_of(StandardError),
            class: described_class.name, message: "Error with delete operation for #{collection_name}")
          expect(result).to eq(['ref1'])
        end
      end
    end

    context 'with mixed operations' do
      before do
        allow(model_class).to receive(:transaction).and_yield
        allow(model_class).to receive(:upsert_all)
        allow(model_class).to receive(:where).and_return(model_class)
        allow(model_class).to receive(:delete_all)
      end

      it 'groups operations by collection and processes both operation types' do
        operations = [
          { 'users' => { upsert: { id: 1, partition_id: 1, name: 'User 1' } }, ref: 'ref1' },
          { 'posts' => { delete: { ref_id: 123 } }, ref: 'ref2' }
        ]

        expect(client).to receive(:with_model_for).with('users').and_yield(model_class)
        expect(client).to receive(:with_model_for).with('posts').and_yield(model_class)

        result = client.bulk_process(operations)

        expect(result).to eq([])
      end
    end
  end

  describe '#with_model_for' do
    let(:table_name) { 'test_table' }

    before do
      allow(connection_pool).to receive(:with_connection).and_yield(ar_connection)
      allow(ar_connection).to receive(:pool).and_return(connection_pool)
    end

    it 'provides a model class configured for the table' do
      client.with_model_for(table_name) do |model|
        expect(model).to be_a(Class)
        expect(model.table_name).to eq(table_name)
        expect(model.connection).to eq(ar_connection)
      end
    end
  end

  describe '#close' do
    it 'disconnects the connection pool' do
      expect(connection_pool).to receive(:disconnect!)

      client.send(:close)
    end

    context 'when connection pool is nil' do
      before do
        allow(connection_model).to receive(:connection_pool).and_return(nil)
      end

      it 'does not raise an error' do
        new_client = described_class.new(options)

        expect { new_client.send(:close) }.not_to raise_error
      end
    end
  end
end
