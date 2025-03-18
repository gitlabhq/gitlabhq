# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Utils::Rake do
  subject(:rake) { described_class.new('version') }

  describe '#execute' do
    it 'clears out bundler environment' do
      expect(Bundler).to receive(:with_original_env).and_yield

      rake.execute
    end

    it 'runs rake using bundle exec' do
      expect_next_instance_of(Gitlab::Backup::Cli::Shell::Command) do |shell|
        expect(shell.cmd_args).to start_with(%w[bundle exec rake])
      end

      rake.execute
    end

    it 'runs rake command with the defined tasks' do
      expect_next_instance_of(Gitlab::Backup::Cli::Shell::Command) do |shell|
        expect(shell.cmd_args).to end_with(%w[version])
      end

      rake.execute

      expect(rake.success?).to eq(true)
    end

    context 'when chdir is set' do
      let(:tmpdir) { Dir.mktmpdir }

      after do
        FileUtils.rm_rf(tmpdir)
      end

      subject(:rake) { described_class.new('current_pwd', chdir: tmpdir) }

      it 'runs rake in the provided chdir directory' do
        expect_next_instance_of(Gitlab::Backup::Cli::Shell::Command) do |shell|
          expect(shell.chdir).to eq(tmpdir)
        end

        FileUtils.cp_r(fixtures_path.join('gitlab_fake').glob('*'), tmpdir)

        rake.execute

        expect(rake.success?).to eq(true)
        expect(rake.output).to match(/#{tmpdir}/)
      end
    end
  end

  describe '#success?' do
    subject(:rake) { described_class.new('--version') } # valid command that has no side-effect

    context 'with a successful rake execution' do
      it 'returns true' do
        rake.execute

        expect(rake.success?).to be_truthy
      end
    end

    context 'with a failed rake execution', :hide_output do
      subject(:invalid_rake) { described_class.new('--invalid') } # valid command that has no side-effect

      it 'returns false when a previous execution failed' do
        invalid_rake.execute

        expect(invalid_rake.duration).to be > 0.0
        expect(invalid_rake.success?).to be_falsey
      end
    end

    it 'returns false when no execution was done before' do
      expect(rake.success?).to be_falsey
    end
  end

  describe '#output' do
    it 'returns the output from running a rake task' do
      rake.execute

      expect(rake.output).to match(Gitlab::Backup::Cli::VERSION)
    end

    it 'returns an empty string when the task has not been run' do
      expect(rake.output).to eq('')
    end
  end

  describe '#stderr' do
    subject(:invalid_rake) { described_class.new('--invalid') } # valid command that has no side-effect

    it 'returns the content from stderr when available' do
      invalid_rake.execute

      expect(invalid_rake.stderr).to match('invalid option: --invalid')
    end

    it 'returns an empty string when the task has not been run' do
      expect(invalid_rake.stderr).to eq('')
    end
  end

  describe '#duration' do
    it 'returns a duration time' do
      rake.execute

      expect(rake.duration).to be > 0.0
    end

    it 'returns 0.0 when the task has not been run' do
      expect(rake.duration).to eq(0.0)
    end
  end
end
