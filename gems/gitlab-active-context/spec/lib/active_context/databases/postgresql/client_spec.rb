# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Postgresql::Client do
  let(:options) do
    {
      host: 'localhost',
      port: 5432,
      database: 'test_db',
      username: 'user',
      password: 'pass',
      pool_size: 2,
      pool_timeout: 1
    }
  end

  subject(:client) { described_class.new(options) }

  describe '#initialize' do
    let(:connection_pool) { instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool) }
    let(:connection_model) { class_double(ActiveRecord::Base) }

    before do
      allow_any_instance_of(described_class).to receive(:create_connection_model)
        .and_return(connection_model)

      allow(connection_model).to receive(:establish_connection)
      allow(connection_model).to receive(:connection_pool).and_return(connection_pool)
    end

    it 'creates a connection pool through ActiveRecord' do
      expected_config = {
        'adapter' => 'postgresql',
        'host' => 'localhost',
        'port' => 5432,
        'database' => 'test_db',
        'username' => 'user',
        'password' => 'pass',
        'connect_timeout' => 5,
        'pool' => 2,
        'prepared_statements' => false,
        'advisory_locks' => false,
        'database_tasks' => false
      }

      expect(connection_model).to receive(:establish_connection)
        .with(hash_including(expected_config))

      client
    end
  end

  describe '#with_raw_connection' do
    let(:raw_connection) { instance_double(PG::Connection) }
    let(:connection_pool) { instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool) }
    let(:ar_connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
    let(:connection_model) { class_double(ActiveRecord::Base) }
    let(:yielded_values) { [] }

    before do
      allow_any_instance_of(described_class).to receive(:create_connection_model)
        .and_return(connection_model)

      allow(connection_model).to receive(:establish_connection)
      allow(connection_model).to receive(:connection_pool).and_return(connection_pool)

      allow(connection_pool).to receive(:with_connection).and_yield(ar_connection)
      allow(ar_connection).to receive_messages(
        raw_connection: raw_connection
      )

      allow(raw_connection).to receive(:server_version).and_return(120000)
    end

    it 'yields raw PostgreSQL connection' do
      client.with_raw_connection do |conn|
        yielded_values << conn
      end

      expect(yielded_values).to eq([raw_connection])
    end
  end

  describe '#with_connection' do
    let(:raw_connection) { instance_double(PG::Connection) }
    let(:connection_pool) { instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool) }
    let(:ar_connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
    let(:connection_model) { class_double(ActiveRecord::Base) }
    let(:yielded_values) { [] }

    before do
      allow_any_instance_of(described_class).to receive(:create_connection_model)
        .and_return(connection_model)

      allow(connection_model).to receive(:establish_connection)
      allow(connection_model).to receive(:connection_pool).and_return(connection_pool)

      allow(connection_pool).to receive(:with_connection).and_yield(ar_connection)
      allow(ar_connection).to receive_messages(
        raw_connection: raw_connection
      )

      allow(raw_connection).to receive(:server_version).and_return(120000)
    end

    it 'yields ActiveRecord connection' do
      client.with_connection do |conn|
        yielded_values << conn
      end

      expect(yielded_values).to eq([ar_connection])
    end
  end

  describe '#search' do
    let(:raw_connection) { instance_double(PG::Connection) }
    let(:query_result) { instance_double(PG::Result) }
    let(:connection_pool) { instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool) }
    let(:ar_connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
    let(:connection_model) { class_double(ActiveRecord::Base) }

    before do
      allow_any_instance_of(described_class).to receive(:create_connection_model)
        .and_return(connection_model)

      allow(connection_model).to receive(:establish_connection)
      allow(connection_model).to receive(:connection_pool).and_return(connection_pool)

      allow(connection_pool).to receive(:with_connection).and_yield(ar_connection)
      allow(ar_connection).to receive_messages(
        execute: query_result,
        raw_connection: raw_connection
      )

      allow(raw_connection).to receive(:server_version).and_return(120000)
      allow(ActiveContext::Databases::Postgresql::QueryResult).to receive(:new)
    end

    it 'executes query and returns QueryResult' do
      expect(ar_connection).to receive(:execute).with('SELECT * FROM pg_stat_activity')
      expect(ActiveContext::Databases::Postgresql::QueryResult)
        .to receive(:new).with(query_result)

      client.search('test query')
    end
  end
end
