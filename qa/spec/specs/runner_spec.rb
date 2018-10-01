# frozen_string_literal: true

describe QA::Specs::Runner do
  context '#perform' do
    before do
      allow(QA::Runtime::Browser).to receive(:configure!)
    end

    it 'excludes the orchestrated tag by default' do
      expect_rspec_runner_arguments(['--tag', '~orchestrated', *described_class::DEFAULT_TEST_PATH_ARGS])

      subject.perform
    end

    context 'when tty is set' do
      subject { described_class.new.tap { |runner| runner.tty = true } }

      it 'sets the `--tty` flag' do
        expect_rspec_runner_arguments(['--tty', '--tag', '~orchestrated', *described_class::DEFAULT_TEST_PATH_ARGS])

        subject.perform
      end
    end

    context 'when tags are set' do
      subject { described_class.new.tap { |runner| runner.tags = %i[orchestrated github] } }

      it 'focuses on the given tags' do
        expect_rspec_runner_arguments(['--tag', 'orchestrated', '--tag', 'github', *described_class::DEFAULT_TEST_PATH_ARGS])

        subject.perform
      end
    end

    context 'when "--tag smoke" is set as options' do
      subject { described_class.new.tap { |runner| runner.options = %w[--tag smoke] } }

      it 'focuses on the given tag without excluded the orchestrated tag' do
        expect_rspec_runner_arguments(['--tag', 'smoke', *described_class::DEFAULT_TEST_PATH_ARGS])

        subject.perform
      end
    end

    context 'when "qa/specs/features/foo" is set as options' do
      subject { described_class.new.tap { |runner| runner.options = %w[qa/specs/features/foo] } }

      it 'passes the given tests path and excludes the orchestrated tag' do
        expect_rspec_runner_arguments(['--tag', '~orchestrated', 'qa/specs/features/foo'])

        subject.perform
      end
    end

    context 'when "-- qa/specs/features/foo" is set as options' do
      subject { described_class.new.tap { |runner| runner.options = %w[-- qa/specs/features/foo] } }

      it 'passes the given tests path and excludes the orchestrated tag' do
        expect_rspec_runner_arguments(['--tag', '~orchestrated', '--', 'qa/specs/features/foo'])

        subject.perform
      end
    end

    def expect_rspec_runner_arguments(arguments)
      expect(RSpec::Core::Runner).to receive(:run)
        .with(arguments, $stderr, $stdout)
        .and_return(0)
    end
  end
end
