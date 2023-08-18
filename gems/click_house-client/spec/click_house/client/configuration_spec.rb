# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Client::Configuration do
  subject(:configuration) do
    config = described_class.new
    config.http_post_proc = -> {}
    config.json_parser = Object
    config
  end

  describe '#register_database' do
    let(:database_options) do
      {
        database: 'test_db',
        url: 'http://localhost:3333',
        username: 'user',
        password: 'pass',
        variables: {
          join_use_nulls: 1
        }
      }
    end

    it 'registers a database' do
      configuration.register_database(:my_db, **database_options)

      expect(configuration.databases.size).to eq(1)
      database = configuration.databases[:my_db]

      expect(database.uri.to_s).to eq('http://localhost:3333?database=test_db&enable_http_compression=1&join_use_nulls=1')
    end

    context 'when adding the same DB multiple times' do
      it 'raises error' do
        configuration.register_database(:my_db, **database_options)
        expect do
          configuration.register_database(:my_db, **database_options)
        end.to raise_error(ClickHouse::Client::ConfigurationError, /database 'my_db' is already registered/)
      end
    end
  end

  describe '#validate!' do
    context 'when `http_post_proc` option is not configured' do
      it 'raises error' do
        configuration.http_post_proc = nil

        expect do
          configuration.validate!
        end.to raise_error(ClickHouse::Client::ConfigurationError, /'http_post_proc' option is not configured/)
      end
    end

    context 'when `json_parser` option is not configured' do
      it 'raises error' do
        configuration.json_parser = nil

        expect do
          configuration.validate!
        end.to raise_error(ClickHouse::Client::ConfigurationError, /'json_parser' option is not configured/)
      end
    end
  end
end
