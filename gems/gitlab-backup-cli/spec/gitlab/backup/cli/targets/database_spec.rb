# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Backup::Cli::Targets::Database do
  let(:context) { build_test_context }
  let(:database) { described_class.new(context) }
  let(:pipeline_success) { instance_double(Gitlab::Backup::Cli::Shell::Pipeline::Result, success?: true) }

  describe '#dump', :silence_output do
    let(:destination) { Pathname(Dir.mktmpdir('database-target', temp_path)) }

    after do
      FileUtils.rm_rf(destination)
    end

    it 'creates the destination directory' do
      mock_database_dump!

      expect(FileUtils).to receive(:mkdir_p).with(destination)

      database.dump(destination)
    end

    it 'triggers a database snapshot' do
      mock_database_dump!

      expect_next_instance_of(Gitlab::Backup::Cli::Services::Database) do |db|
        expect(db).to receive(:export_snapshot!).and_call_original
      end.at_least(:once)

      database.dump(destination)
    end

    it 'dumps the database' do
      database.dump(destination)

      database_dump_files = Dir.glob(destination.join('*.sql.gz'))

      expect(database_dump_files).not_to be_empty
    end

    it 'releases the snapshot after dumping' do
      mock_database_dump!

      expect_next_instance_of(Gitlab::Backup::Cli::Services::Database) do |db|
        expect(db).to receive(:release_snapshot!).and_call_original
      end.at_least(:once)

      database.dump(destination)
    end

    it 'restores timeout after dumping' do
      mock_database_dump!

      expect_next_instance_of(Gitlab::Backup::Cli::Services::Database) do |db|
        expect(db).to receive(:restore_timeouts!).and_call_original
      end.at_least(:once)

      database.dump(destination)
    end

    it 'raises an error if the dump fails' do
      false_command = Gitlab::Backup::Cli::Shell::Command.new(%q(false))
      replace_database_dump_command!(false_command)

      expect { database.dump(destination) }.to raise_error(Gitlab::Backup::Cli::Errors::DatabaseBackupError)
    end
  end

  describe '#restore' do
    let(:source) { Pathname(Dir.mktmpdir('database-target', temp_path)) }

    after do
      FileUtils.rm_rf(source)
    end

    context 'with an invalid backup source' do
      it 'raises an error when main database backup file is missing' do
        mock_databases_collection('main')

        expect { database.restore(source) }.to raise_error(Gitlab::Backup::Cli::Error).with_message(
          /Database backup file '[^']*' for the main database does not exist/
        )
      end

      it 'raises an warning when other database backup files are missing' do
        mock_databases_collection('ci')

        expect { database.restore(source) }.to output(
          /Database backup file '[^']*' for the ci database does not exist/
        ).to_stderr
      end
    end

    context 'with a valid backup file' do
      it 'drops all tables before restoring' do
        allow(database).to receive(:restore_tables).and_return(
          pipeline_success
        )

        mock_databases_collection('main') do |db|
          FileUtils.touch(source.join('database.sql.gz'))

          expect(database).to receive(:drop_tables).with(db)
        end

        database.restore(source)
      end

      it 'restores the database' do
        allow(database).to receive(:drop_tables)

        mock_databases_collection('main') do |db|
          filepath = source.join('database.sql.gz')
          FileUtils.touch(filepath)

          expect(database).to receive(:restore_tables).with(database: db, filepath: filepath).and_return(
            pipeline_success
          )
        end

        database.restore(source)
      end
    end
  end

  def mock_databases_collection(dbname)
    allow_next_instance_of(Gitlab::Backup::Cli::Services::Postgres) do |databases|
      entry = databases.send(:entries).find { |db| db.configuration.name == dbname }

      allow(databases).to receive(:each).and_yield(entry)

      yield entry if block_given?
    end
  end

  def mock_database_dump!
    echo_command = Gitlab::Backup::Cli::Shell::Command.new(%q(echo ''))

    replace_database_dump_command!(echo_command)
  end

  def replace_database_dump_command!(new_command)
    allow_next_instance_of(::Gitlab::Backup::Cli::Utils::PgDump) do |pg_dump|
      allow(pg_dump).to receive(:build_command).and_return(new_command)
    end
  end
end
