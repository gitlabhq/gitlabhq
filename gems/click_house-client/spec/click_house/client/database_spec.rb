# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Client::Database do
  subject(:database) do
    described_class.new(
      database: 'test_db',
      url: 'http://localhost:3333',
      username: 'user',
      password: 'pass',
      variables: {
        join_use_nulls: 1
      }
    )
  end

  describe '#uri' do
    it 'builds the correct URL' do
      expect(database.uri.to_s).to eq('http://localhost:3333?database=test_db&enable_http_compression=1&join_use_nulls=1')
    end
  end

  describe '#headers' do
    it 'returns the correct headers' do
      expect(database.headers).to eq({
        "X-ClickHouse-Format" => "JSON",
        'X-ClickHouse-User' => 'user',
        'X-ClickHouse-Key' => 'pass'
      })
    end
  end

  describe '#with_default_database' do
    it 'returns a new Database instance with default database' do
      default_db = database.with_default_database

      expect(default_db).to be_a(described_class)
      expect(default_db).not_to eq(database)
      expect(default_db.database).to eq('default')
    end

    it 'preserves original URL, username, and password' do
      default_db = database.with_default_database

      expect(default_db.uri.host).to eq(database.uri.host)
      expect(default_db.uri.port).to eq(database.uri.port)
      expect(default_db.headers['X-ClickHouse-User']).to eq('user')
      expect(default_db.headers['X-ClickHouse-Key']).to eq('pass')
    end

    it 'merges variables with database set to default' do
      default_db = database.with_default_database

      expect(default_db.uri.to_s).to eq('http://localhost:3333?database=default&enable_http_compression=1&join_use_nulls=1')
    end

    it 'overrides original database in variables' do
      default_db = database.with_default_database
      query_params = default_db.uri.query_values

      expect(query_params['database']).to eq('default')
      expect(query_params['join_use_nulls']).to eq('1')
      expect(query_params['enable_http_compression']).to eq('1')
    end

    it 'does not modify the original database instance' do
      original_database_name = database.database
      original_uri = database.uri.to_s

      database.with_default_database

      expect(database.database).to eq(original_database_name)
      expect(database.uri.to_s).to eq(original_uri)
    end
  end
end
