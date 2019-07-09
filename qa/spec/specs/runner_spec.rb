# frozen_string_literal: true

require 'active_support/core_ext/hash'

describe QA::Specs::Runner do
  shared_examples 'excludes orchestrated' do
    it 'excludes the orchestrated tag and includes default args' do
      expect_rspec_runner_arguments(['--tag', '~orchestrated', *described_class::DEFAULT_TEST_PATH_ARGS])

      subject.perform
    end
  end

  context '#perform' do
    before do
      allow(QA::Runtime::Browser).to receive(:configure!)
    end

    it_behaves_like 'excludes orchestrated'

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

    context 'when "--tag smoke" and "qa/specs/features/foo" are set as options' do
      subject { described_class.new.tap { |runner| runner.options = %w[--tag smoke qa/specs/features/foo] } }

      it 'focuses on the given tag and includes the path without excluding the orchestrated tag' do
        expect_rspec_runner_arguments(['--tag', 'smoke', 'qa/specs/features/foo'])

        subject.perform
      end
    end

    context 'when SIGNUP_DISABLED is true' do
      before do
        allow(QA::Runtime::Env).to receive(:signup_disabled?).and_return(true)
      end

      it 'includes default args and excludes the skip_signup_disabled tag' do
        expect_rspec_runner_arguments(['--tag', '~orchestrated', '--tag', '~skip_signup_disabled', *described_class::DEFAULT_TEST_PATH_ARGS])

        subject.perform
      end
    end

    context 'testable features' do
      shared_examples 'one supported feature' do |feature|
        before do
          QA::Runtime::Env.supported_features.each do |tag, _|
            allow(QA::Runtime::Env).to receive(:can_test?).with(tag).and_return(false)
          end

          allow(QA::Runtime::Env).to receive(:can_test?).with(feature).and_return(true) unless feature.nil?
        end

        it 'includes default args and excludes all unsupported tags' do
          expect_rspec_runner_arguments(['--tag', '~orchestrated', *excluded_feature_tags_except(feature), *described_class::DEFAULT_TEST_PATH_ARGS])

          subject.perform
        end
      end

      context 'when only git protocol 2 is supported' do
        it_behaves_like 'one supported feature', :git_protocol_v2
      end

      context 'when only admin features are supported' do
        it_behaves_like 'one supported feature', :admin
      end

      context 'when no features are supported' do
        it_behaves_like 'one supported feature', nil
      end

      context 'when all features are supported' do
        before do
          QA::Runtime::Env.supported_features.each do |tag, _|
            allow(QA::Runtime::Env).to receive(:can_test?).with(tag).and_return(true)
          end
        end

        it_behaves_like 'excludes orchestrated'
      end

      context 'when features are not specified' do
        it_behaves_like 'excludes orchestrated'
      end
    end

    def excluded_feature_tags_except(tag)
      QA::Runtime::Env.supported_features.except(tag).map do |tag, _|
        ['--tag', "~requires_#{tag}"]
      end.flatten
    end

    def expect_rspec_runner_arguments(arguments)
      expect(RSpec::Core::Runner).to receive(:run)
        .with(arguments, $stderr, $stdout)
        .and_return(0)
    end
  end
end
