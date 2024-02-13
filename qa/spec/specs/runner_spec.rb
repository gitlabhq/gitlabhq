# frozen_string_literal: true

RSpec.describe QA::Specs::Runner do
  shared_examples 'excludes default skipped, and geo' do
    it 'excludes the default skipped and geo tags, and includes default args' do
      expect_rspec_runner_arguments(DEFAULT_SKIPPED_TAGS + ['--tag', '~geo', *described_class::DEFAULT_TEST_PATH_ARGS])

      subject.perform
    end
  end

  before do
    stub_const('DEFAULT_SKIPPED_TAGS', %w[--tag ~orchestrated --tag ~transient].freeze)
  end

  describe '#perform' do
    before do
      allow(QA::Runtime::Browser).to receive(:configure!)

      QA::Runtime::Scenario.define(:gitlab_address, "http://gitlab.test")
      QA::Runtime::Scenario.define(:klass, "QA::Scenario::Test::Instance::All")
    end

    it_behaves_like 'excludes default skipped, and geo'

    context 'when tty is set' do
      subject { described_class.new.tap { |runner| runner.tty = true } }

      it 'sets the `--tty` flag' do
        expect_rspec_runner_arguments(
          ['--tty'] + DEFAULT_SKIPPED_TAGS + ['--tag', '~geo', *described_class::DEFAULT_TEST_PATH_ARGS]
        )

        subject.perform
      end
    end

    context 'when count_examples_only is set as an option' do
      let(:out) { StringIO.new }

      before do
        QA::Runtime::Scenario.define(:count_examples_only, true)
        out.string = '22 examples,'
        allow(StringIO).to receive(:new).and_return(out)
      end

      it 'sets the `--dry-run` flag' do
        expect_rspec_runner_arguments(
          ['--dry-run'] + DEFAULT_SKIPPED_TAGS + ['--tag', '~geo', *described_class::DEFAULT_TEST_PATH_ARGS],
          [$stderr, anything]
        )

        subject.perform
      end

      it 'writes to file when examples are more than zero' do
        allow(RSpec::Core::Runner).to receive(:run).and_return(0)

        expect(File).to receive(:open).with('no_of_examples/test_instance_all.txt', 'w') { '22' }

        subject.perform
      end

      it 'does not write to file when zero examples' do
        out.string = '0 examples,'
        allow(RSpec::Core::Runner).to receive(:run).and_return(0)

        expect(File).not_to receive(:open)

        subject.perform
      end

      it 'raises error when Rspec output does not match regex' do
        out.string = '0'
        allow(RSpec::Core::Runner).to receive(:run).and_return(0)

        expect { subject.perform }
          .to raise_error(QA::Specs::Runner::RegexMismatchError, 'Rspec output did not match regex')
      end

      context 'when --tag is specified as an option' do
        subject { described_class.new.tap { |runner| runner.options = %w[--tag actioncable] } }

        it 'includes the option value in the file name' do
          expect_rspec_runner_arguments(
            ['--dry-run', '--tag', '~geo', '--tag', 'actioncable', *described_class::DEFAULT_TEST_PATH_ARGS],
            [$stderr, anything]
          )

          expect(File).to receive(:open).with('no_of_examples/test_instance_all_actioncable.txt', 'w') { '22' }

          subject.perform
        end
      end

      after do
        QA::Runtime::Scenario.attributes.delete(:count_examples_only)
      end
    end

    context 'when test_metadata_only is set as an option' do
      let(:rspec_config) { instance_double('RSpec::Core::Configuration') }
      let(:output_file) { Pathname.new('/root/tmp/test-metadata.json') }

      before do
        QA::Runtime::Scenario.define(:test_metadata_only, true)
        allow(RSpec).to receive(:configure).and_yield(rspec_config)
        allow(rspec_config).to receive(:add_formatter)
        allow(rspec_config).to receive(:fail_if_no_examples=)
      end

      it 'sets the `--dry-run` flag' do
        expect_rspec_runner_arguments(
          ['--dry-run', *described_class::DEFAULT_TEST_PATH_ARGS],
          [$stderr, anything]
        )

        subject.perform
      end

      it 'configures json formatted output to file' do
        allow(QA::Runtime::Path).to receive(:qa_root).and_return('/root')

        expect(rspec_config).to receive(:add_formatter)
          .with(QA::Support::JsonFormatter, output_file)
        expect(rspec_config).to receive(:fail_if_no_examples=)
          .with(true)

        allow(RSpec::Core::Runner).to receive(:run).and_return(0)

        subject.perform
      end

      after do
        QA::Runtime::Scenario.attributes.delete(:test_metadata_only)
      end
    end

    context 'when tags are set' do
      subject { described_class.new.tap { |runner| runner.tags = %i[orchestrated github] } }

      it 'focuses on the given tags' do
        expect_rspec_runner_arguments(
          ['--tag', 'orchestrated', '--tag', 'github', '--tag', '~geo', *described_class::DEFAULT_TEST_PATH_ARGS]
        )

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

      it 'passes the given tests path and excludes the default skipped, and geo tags' do
        expect_rspec_runner_arguments(DEFAULT_SKIPPED_TAGS + ['--tag', '~geo', 'qa/specs/features/foo'])

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
        expect_rspec_runner_arguments(DEFAULT_SKIPPED_TAGS + ['--tag', '~geo', '--tag', '~skip_signup_disabled', *described_class::DEFAULT_TEST_PATH_ARGS])

        subject.perform
      end
    end

    context 'when running against live environment' do
      before do
        QA::Runtime::Scenario.define(:gitlab_address, "https://staging.gitlab.com")
      end

      it 'includes default args and excludes the skip_live_env tag' do
        expect_rspec_runner_arguments(DEFAULT_SKIPPED_TAGS + ['--tag', '~geo', '--tag', '~skip_live_env', *described_class::DEFAULT_TEST_PATH_ARGS])
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
          expect_rspec_runner_arguments(
            DEFAULT_SKIPPED_TAGS + ['--tag', '~geo', *excluded_feature_tags_except(feature),
                                    *described_class::DEFAULT_TEST_PATH_ARGS]
          )

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

        it_behaves_like 'excludes default skipped, and geo'
      end

      context 'when features are not specified' do
        it_behaves_like 'excludes default skipped, and geo'
      end
    end

    def excluded_feature_tags_except(tag)
      QA::Runtime::Env.supported_features.except(tag).flat_map do |tag, _|
        ['--tag', "~requires_#{tag}"]
      end
    end

    def expect_rspec_runner_arguments(arguments, std_arguments = described_class::DEFAULT_STD_ARGS)
      expect(RSpec::Core::Runner).to receive(:run)
                                       .with(arguments, *std_arguments)
                                       .and_return(0)
    end
  end
end
