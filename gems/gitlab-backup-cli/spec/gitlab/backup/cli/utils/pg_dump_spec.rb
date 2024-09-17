# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Utils::PgDump do
  let(:cmd_args) { pg_dump.send(:cmd_args) }
  let(:database_name) { 'gitlab_database' }
  let(:env) do
    {
      'PGHOST' => '192.168.99.99',
      'PGPORT' => '5434'
    }
  end

  subject(:pg_dump) { described_class.new(database_name: database_name) }

  context 'with accessors' do
    it { respond_to :database_name }
    it { respond_to :snapshot_id }
    it { respond_to :schemas }
    it { respond_to :env }
  end

  describe '#cmd_args' do
    let(:default_args) { %w[--clean --if-exists] }

    context 'when no optional parameter is provided' do
      it 'returns default arguments' do
        expect(cmd_args).to eq(default_args << database_name)
      end
    end

    context 'with custom snapshot_id' do
      let(:snapshot_id) { '00000003-000001BF-1' }

      subject(:pg_dump) { described_class.new(database_name: database_name, snapshot_id: snapshot_id) }

      it 'adds a flag between default_args and the database name' do
        expect(cmd_args).to eq(default_args + %W[--snapshot=#{snapshot_id} #{database_name}])
      end
    end

    context 'with custom schemas' do
      let(:schemas) { %w[public gitlab_partitions_dynamic gitlab_partitions_static] }

      subject(:pg_dump) { described_class.new(database_name: database_name, schemas: schemas) }

      it 'adds additional flags for each schema' do
        schemas_args = %W[-n #{schemas[0]} -n #{schemas[1]} -n #{schemas[2]}]
        expected_args = (default_args + schemas_args) << database_name

        expect(cmd_args).to eq(expected_args)
      end
    end
  end

  describe '#spawn' do
    it 'returns a spawned process' do
      process = instance_double(Process)
      expect(Process).to receive(:spawn).and_return(process)

      expect(pg_dump.spawn(output: StringIO)).to eq(process)
    end

    it 'forwards cmd_args to Process spawn' do
      expect(Process).to receive(:spawn).with({}, 'pg_dump', *cmd_args, any_args)

      pg_dump.spawn(output: StringIO)
    end

    context 'when env variables are provided' do
      subject(:pg_dump) { described_class.new(database_name: database_name, env: env) }

      it 'forwards provided env variables to Process spawn' do
        expect(Process).to receive(:spawn).with(env, 'pg_dump', any_args)

        pg_dump.spawn(output: StringIO)
      end
    end
  end
end
