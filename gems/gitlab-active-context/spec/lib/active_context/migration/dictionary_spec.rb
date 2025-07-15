# frozen_string_literal: true

RSpec.describe ActiveContext::Migration::Dictionary do
  let(:migration_path) { File.join(Dir.tmpdir, 'active_context_migrations') }

  before do
    FileUtils.mkdir_p(migration_path)
    allow(ActiveContext::Config).to receive(:migrations_path).and_return(migration_path)
  end

  after do
    FileUtils.rm_rf(migration_path)
  end

  describe '#migrations' do
    context 'when there are no migration files' do
      it 'returns an empty array' do
        expect(described_class.new.migrations).to be_empty
      end
    end

    context 'when there are migration files' do
      before do
        create_migration_file('20220101000001_create_table', <<~RUBY)
          class CreateTable
            def up; end
          end
        RUBY

        create_migration_file('20220101000002_add_column', <<~RUBY)
          class AddColumn
            def up; end
          end
        RUBY
      end

      it 'loads all migrations sorted by version' do
        dictionary = described_class.new
        migrations = dictionary.migrations

        expect(migrations.size).to eq(2)
        expect(migrations.first.name).to eq('ActiveContext::Migration::V20220101000001::CreateTable')
        expect(migrations.last.name).to eq('ActiveContext::Migration::V20220101000002::AddColumn')
      end

      it 'returns only versions when versions_only is true' do
        dictionary = described_class.new
        versions = dictionary.migrations(versions_only: true)

        expect(versions).to eq(%w[20220101000001 20220101000002])
      end
    end
  end

  describe '#find_by_version' do
    before do
      create_migration_file('20220101000001_create_table', <<~RUBY)
        class CreateTable
          def up; end
        end
      RUBY
    end

    it 'finds a migration by version number' do
      dictionary = described_class.new
      migration = dictionary.find_by_version('20220101000001')

      expect(migration).to be_a(Class)
      expect(migration.name).to eq('ActiveContext::Migration::V20220101000001::CreateTable')
    end

    it 'returns nil when version does not exist' do
      dictionary = described_class.new
      migration = dictionary.find_by_version('99999999999999')

      expect(migration).to be_nil
    end
  end

  describe '#find_version_by_class_name' do
    before do
      create_migration_file('20220101000001_create_table', <<~RUBY)
        module ActiveContext
          class CreateTable
            def up; end
          end
        end
      RUBY
    end

    it 'finds a version by class name' do
      dictionary = described_class.new
      version = dictionary.find_version_by_class_name('CreateTable')

      expect(version).to eq('20220101000001')
    end

    it 'returns nil when class name does not exist' do
      dictionary = described_class.new
      version = dictionary.find_version_by_class_name('NonExistentClass')

      expect(version).to be_nil
    end
  end

  describe 'error handling' do
    it 'raises an error when migration file has invalid format' do
      create_migration_file('invalid_migration_name', <<~RUBY)
        class InvalidMigration
          def up; end
        end
      RUBY

      expect { described_class.new }.to raise_error(
        ActiveContext::Migration::Dictionary::InvalidMigrationNameError,
        /Invalid migration file name format/
      )
    end
  end

  def create_migration_file(name, content)
    path = File.join(migration_path, "#{name}.rb")
    File.write(path, content)
  end
end
