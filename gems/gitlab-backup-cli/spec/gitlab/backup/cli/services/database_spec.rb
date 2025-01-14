# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Services::Database do
  let(:database_yml) { YAML.load_file(fixtures_path.join('config/database.yml'), aliases: true) }
  let(:mocked_configuration) do
    ActiveRecord::DatabaseConfigurations.new(database_yml).configs_for(env_name: 'test', include_hidden: false).first
  end

  let(:test_configuration) do
    Gitlab::Backup::Cli::Services::Postgres.new(build_test_context).send(:database_configurations).first
  end

  let(:connection) { database.send(:connection) }

  context 'with mocked configuration' do
    subject(:database) { described_class.new(mocked_configuration) }

    describe '#initialize' do
      it 'initializes a database with provided configuration' do
        expect { database }.not_to raise_error
        expect(database.configuration).to eq(mocked_configuration)
      end
    end

    describe '#pg_env_variables' do
      it 'returns a hash' do
        expect(database.pg_env_variables).to be_a(Hash)
      end

      it 'expects PG ENV variables pointing to configured values' do
        expected = {
          'PGUSER' => 'postgres',
          'PGHOST' => 'localhost'
        }
        expect(database.pg_env_variables).to include(expected)
      end
    end

    describe '#connection_params' do
      it 'returns a connection hash data' do
        expected = {
          adapter: 'postgresql',
          database: 'gitlabhq_test',
          encoding: 'unicode',
          username: 'postgres',
          host: 'localhost',
          password: nil,
          prepared_statements: false,
          variables: {
            'statement_timeout' => '15s'
          }
        }

        expect(database.connection_params).to be_a(Hash)
        expect(database.connection_params).to include(expected)
      end
    end
  end

  context 'with test connection' do
    subject(:database) { described_class.new(test_configuration) }

    describe '#export_snapshot!' do
      after do
        database.restore_timeouts!
      end

      it 'delegates disabling timeouts to #disable_timeouts!' do
        expect(database).to receive(:disable_timeouts!)

        database.export_snapshot!
      end

      it 'sets a snapshot_id' do
        expect { database.export_snapshot! }.to change { database.snapshot_id }
      end
    end

    describe '#release_snapshot!' do
      it 'clears a previous set snapshot id' do
        database.export_snapshot!

        expect(connection).to receive(:rollback_transaction).and_call_original

        expect { database.release_snapshot! }.to change { database.snapshot_id }.to(nil)
      end
    end

    describe 'disable_timeouts!' do
      after do
        database.restore_timeouts!
      end

      it 'changes connection timeout value to zero' do
        connection.execute('SET idle_in_transaction_session_timeout = 60')

        expect { database.disable_timeouts! }.to change { fetch_timeout }.to '0'
      end
    end

    describe 'restore_timeouts!' do
      it 'restores timeout to default value' do
        original_timeout = fetch_timeout

        connection.execute('SET idle_in_transaction_session_timeout = 999')

        expect { database.restore_timeouts! }.to change { fetch_timeout }.to original_timeout
      end
    end

    def fetch_timeout
      connection.execute('SHOW idle_in_transaction_session_timeout').getvalue(0, 0)
    end
  end
end
