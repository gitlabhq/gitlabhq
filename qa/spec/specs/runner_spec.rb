# frozen_string_literal: true

RSpec.describe QA::Specs::Runner do
  shared_examples 'excludes orchestrated, transient, and geo' do
    it 'excludes the orchestrated, transient, and geo tags, and includes default args' do
      expect_rspec_runner_arguments(['--tag', '~orchestrated', '--tag', '~transient', '--tag', '~geo', *described_class::DEFAULT_TEST_PATH_ARGS])

      subject.perform
    end
  end

  describe '#perform' do
    before do
      allow(QA::Runtime::Browser).to receive(:configure!)

      QA::Runtime::Scenario.define(:gitlab_address, "http://gitlab.test")
    end

    it_behaves_like 'excludes orchestrated, transient, and geo'

    context 'when tty is set' do
      subject { described_class.new.tap { |runner| runner.tty = true } }

      it 'sets the `--tty` flag' do
        expect_rspec_runner_arguments(['--tty', '--tag', '~orchestrated', '--tag', '~transient', '--tag', '~geo', *described_class::DEFAULT_TEST_PATH_ARGS])

        subject.perform
      end
    end

    context 'when tags are set' do
      subject { described_class.new.tap { |runner| runner.tags = %i[orchestrated github] } }

      it 'focuses on the given tags' do
        expect_rspec_runner_arguments(['--tag', 'orchestrated', '--tag', 'github', '--tag', '~geo', *described_class::DEFAULT_TEST_PATH_ARGS])

        subject.perform
      end
    end

    context 'when "--tag smoke" is set as options' do
      subject { described_class.new.tap { |runner| runner.options = %w[--tag smoke] } }

      it 'focuses on the given tag without excluded tags' do
        expect_rspec_runner_arguments(['--tag', '~geo', '--tag', 'smoke', *described_class::DEFAULT_TEST_PATH_ARGS])

        subject.perform
      end
    end

    context 'when "qa/specs/features/foo" is set as options' do
      subject { described_class.new.tap { |runner| runner.options = %w[qa/specs/features/foo] } }

      it 'passes the given tests path and excludes the orchestrated, transient, and geo tags' do
        expect_rspec_runner_arguments(['--tag', '~orchestrated', '--tag', '~transient', '--tag', '~geo', 'qa/specs/features/foo'])

        subject.perform
      end
    end

    context 'when "--tag smoke" and "qa/specs/features/foo" are set as options' do
      subject { described_class.new.tap { |runner| runner.options = %w[--tag smoke qa/specs/features/foo] } }

      it 'focuses on the given tag and includes the path without excluding the orchestrated or transient tags' do
        expect_rspec_runner_arguments(['--tag', '~geo', '--tag', 'smoke', 'qa/specs/features/foo'])

        subject.perform
      end
    end

    context 'when SIGNUP_DISABLED is true' do
      before do
        allow(QA::Runtime::Env).to receive(:signup_disabled?).and_return(true)
      end

      it 'includes default args and excludes the skip_signup_disabled tag' do
        expect_rspec_runner_arguments(['--tag', '~orchestrated', '--tag', '~transient', '--tag', '~geo', '--tag', '~skip_signup_disabled', *described_class::DEFAULT_TEST_PATH_ARGS])

        subject.perform
      end
    end

    context 'when running against live environment' do
      before do
        QA::Runtime::Scenario.define(:gitlab_address, "https://staging.gitlab.com")
      end

      it 'includes default args and excludes the skip_live_env tag' do
        expect_rspec_runner_arguments(['--tag', '~orchestrated', '--tag', '~transient', '--tag', '~geo', '--tag', '~skip_live_env', *described_class::DEFAULT_TEST_PATH_ARGS])
        subject.perform
      end
    end

    context 'when running against a Geo environment' do
      before do
        QA::Runtime::Scenario.define(:geo_secondary_address, "https://geo.staging.gitlab.com")
      end

      after do
        QA::Runtime::Scenario.attributes.delete(:geo_secondary_address)
      end

      subject { described_class.new.tap { |runner| runner.tags = %i[geo] } }

      it 'includes the geo tag' do
        expect_rspec_runner_arguments(['--tag', 'geo', *described_class::DEFAULT_TEST_PATH_ARGS])
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
          expect_rspec_runner_arguments(['--tag', '~orchestrated', '--tag', '~transient', '--tag', '~geo', *excluded_feature_tags_except(feature), *described_class::DEFAULT_TEST_PATH_ARGS])

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

        it_behaves_like 'excludes orchestrated, transient, and geo'
      end

      context 'when features are not specified' do
        it_behaves_like 'excludes orchestrated, transient, and geo'
      end
    end

    def excluded_feature_tags_except(tag)
      QA::Runtime::Env.supported_features.except(tag).flat_map do |tag, _|
        ['--tag', "~requires_#{tag}"]
      end
    end

    def expect_rspec_runner_arguments(arguments)
      expect(RSpec::Core::Runner).to receive(:run)
        .with(arguments, $stderr, $stdout)
        .and_return(0)
    end
  end
end
