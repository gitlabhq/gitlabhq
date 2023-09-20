# frozen_string_literal: true

RSpec.describe ClickHouse::Client do
  describe '#select' do
    # Assuming we have a DB table with the following schema
    #
    # CREATE TABLE issues (
    #   `id` UInt64,
    #   `title` String DEFAULT '',
    #   `description` Nullable(String),
    #   `created_at` DateTime64(6, 'UTC') DEFAULT now(),
    #   `updated_at` DateTime64(6, 'UTC') DEFAULT now()
    # )
    # ENGINE = ReplacingMergeTree(updated_at)
    # ORDER BY (id)

    let(:query_result_fixture) { File.expand_path('../fixtures/query_result.json', __dir__) }

    let(:database_config) do
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

    let(:configuration) do
      ClickHouse::Client::Configuration.new.tap do |config|
        config.log_proc = ->(query) do
          { query_string: query.to_sql }
        end
        config.register_database(:test_db, **database_config)
        config.http_post_proc = ->(_url, _headers, _query) {
          body = File.read(query_result_fixture)
          ClickHouse::Client::Response.new(body, 200)
        }
      end
    end

    it 'parses the results and returns the data as array of hashes' do
      result = described_class.select('SELECT * FROM issues', :test_db, configuration)

      timestamp1 = ActiveSupport::TimeZone["UTC"].parse('2023-06-21 13:33:44')
      timestamp2 = ActiveSupport::TimeZone["UTC"].parse('2023-06-21 13:33:50')
      timestamp3 = ActiveSupport::TimeZone["UTC"].parse('2023-06-21 13:33:40')

      expect(result).to eq([
        {
          'id' => 2,
          'title' => 'Title 2',
          'description' => 'description',
          'created_at' => timestamp1,
          'updated_at' => timestamp1
        },
        {
          'id' => 3,
          'title' => 'Title 3',
          'description' => nil,
          'created_at' => timestamp2,
          'updated_at' => timestamp2
        },
        {
          'id' => 1,
          'title' => 'Title 1',
          'description' => 'description',
          'created_at' => timestamp3,
          'updated_at' => timestamp3
        }
      ])
    end

    context 'when the DB is not configured' do
      it 'raises error' do
        expect do
          described_class.select('SELECT * FROM issues', :different_db, configuration)
        end.to raise_error(ClickHouse::Client::ConfigurationError, /not configured/)
      end
    end

    context 'when error response is returned' do
      let(:configuration) do
        ClickHouse::Client::Configuration.new.tap do |config|
          config.register_database(:test_db, **database_config)
          config.http_post_proc = ->(_url, _headers, _query) {
            ClickHouse::Client::Response.new('some error', 404)
          }
        end
      end

      it 'raises error' do
        expect do
          described_class.select('SELECT * FROM issues', :test_db, configuration)
        end.to raise_error(ClickHouse::Client::DatabaseError, 'some error')
      end
    end

    describe 'default logging' do
      let(:fake_logger) { instance_double("Logger", info: 'logged!') }
      let(:query_string) { 'SELECT * FROM issues' }

      before do
        configuration.logger = fake_logger
      end

      shared_examples 'proper logging' do
        it 'calls the custom logger and log_proc' do
          expect(fake_logger).to receive(:info).at_least(:once).with({ query_string: query_string })

          described_class.select(query_object, :test_db, configuration)
        end
      end

      context 'when query is a string' do # rubocop:disable RSpec/MultipleMemoizedHelpers
        let(:query_object) { query_string }

        it_behaves_like 'proper logging'
      end

      context 'when query is a Query object' do # rubocop:disable RSpec/MultipleMemoizedHelpers
        let(:query_object) { ClickHouse::Client::Query.new(raw_query: query_string) }

        it_behaves_like 'proper logging'
      end
    end
  end
end
