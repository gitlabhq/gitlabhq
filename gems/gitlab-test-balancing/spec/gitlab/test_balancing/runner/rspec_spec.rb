# frozen_string_literal: true

require 'spec_helper'

# The runner collaborates with several RSpec internals (config, world, options,
# reporter) plus the client, so specs legitimately need several doubles.
# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe Gitlab::TestBalancing::Runner::Rspec do
  let(:client) { instance_double(Gitlab::TestBalancing::Client) }
  let(:rspec_args) { [] }
  let(:test_splits) do
    [{ path: '01_spec.rb', expected_duration: 65 }, { path: '03_spec.rb', expected_duration: nil }]
  end

  subject(:runner) do
    described_class.new(test_splits: test_splits, rspec_args: rspec_args, client: client)
  end

  describe '#run' do
    context 'when the feature is unavailable' do
      before do
        allow(client).to receive(:initialize_balancing)
          .and_raise(Gitlab::TestBalancing::Client::FeatureUnavailableError)
      end

      it 'returns an unavailable result without booting RSpec or draining' do
        expect(client).not_to receive(:request)

        result = runner.run

        expect(result).to have_attributes(status: 0, unavailable: true)
        expect(result.unavailable?).to be(true)
      end
    end

    context 'when balancing runs' do
      let(:config) do
        instance_double(RSpec::Core::Configuration, failure_exit_code: 1, error_exit_code: nil).tap do |config|
          reporter = instance_double(RSpec::Core::Reporter)
          allow(config).to receive(:reporter).and_return(reporter)
          allow(reporter).to receive(:report).and_yield(reporter)
          allow(config).to receive(:with_suite_hooks).and_yield
        end
      end

      let(:world) { instance_double(RSpec::Core::World, wants_to_quit: false, non_example_failure: false) }
      let(:options) { instance_double(RSpec::Core::ConfigurationOptions) }

      before do
        allow(client).to receive(:initialize_balancing)
          .and_return(Gitlab::TestBalancing::Client::Result.new(mode: 'seed', test_splits: [{ path: '01_spec.rb' }]))
        allow(runner).to receive(:boot_rspec) do
          runner.instance_variable_set(:@config, config)
          runner.instance_variable_set(:@world, world)
          runner.instance_variable_set(:@options, options)
          runner.instance_variable_set(:@executed_examples, [])
        end
        allow(runner).to receive(:run_batch).and_return(true)
        allow(runner).to receive(:persist_example_statuses)
      end

      it 'seeds the given splits, then runs batches until the queue is empty' do
        expect(client).to receive(:initialize_balancing).with(test_splits)
          .and_return(Gitlab::TestBalancing::Client::Result.new(mode: 'seed', test_splits: [{ path: '01_spec.rb' }]))
        expect(client).to receive(:request).and_return([{ path: '03_spec.rb' }], [])
        expect(runner).to receive(:run_batch).with([{ path: '01_spec.rb' }]).and_return(true)
        expect(runner).to receive(:run_batch).with([{ path: '03_spec.rb' }]).and_return(true)

        expect(runner.run).to have_attributes(status: 0, unavailable: false)
      end

      it 'keeps requesting batches after a retry-mode first batch (early-crash retry)' do
        expect(client).to receive(:request).and_return([])
        expect(runner).to receive(:run_batch).with([{ path: '01_spec.rb' }]).and_return(true)

        expect(runner.run.passed?).to be(true)
      end

      it 'returns the failure exit code when a batch has a failure' do
        allow(client).to receive(:request).and_return([])
        allow(runner).to receive(:run_batch).and_return(false)

        result = runner.run

        expect(result).to have_attributes(status: 1, unavailable: false)
        expect(result.passed?).to be(false)
      end

      it 'fails when an error occurs outside examples even if all examples passed' do
        allow(client).to receive(:request).and_return([])
        allow(runner).to receive(:run_batch).and_return(true)
        allow(world).to receive(:non_example_failure).and_return(true)

        result = runner.run

        expect(result).to have_attributes(status: 1, unavailable: false)
        expect(result.passed?).to be(false)
      end

      it 'prefers error_exit_code over failure_exit_code for non-example failures' do
        allow(client).to receive(:request).and_return([])
        allow(runner).to receive(:run_batch).and_return(true)
        allow(world).to receive(:non_example_failure).and_return(true)
        allow(config).to receive(:error_exit_code).and_return(2)

        expect(runner.run.status).to eq(2)
      end

      context 'when RSpec wants to quit (fail-fast limit met or interrupt)' do
        it 'stops requesting further batches once world.wants_to_quit is set' do
          # First batch runs, then fail-fast trips: no more batches should be pulled.
          allow(world).to receive(:wants_to_quit).and_return(true)
          expect(runner).to receive(:run_batch).and_return(false)
          expect(client).not_to receive(:request)

          expect(runner.run.passed?).to be(false)
        end
      end

      context 'when the run raises (e.g. a profiler crashes during teardown)' do
        it 'still persists example statuses so retries can run, then re-raises' do
          allow(runner).to receive(:persist_example_statuses).and_call_original
          allow(runner).to receive(:run_batch).and_raise(TypeError, 'boom')
          # Reach the persistence path without doing real file IO.
          allow(config).to receive(:example_status_persistence_file_path).and_return(nil)

          expect(runner).to receive(:persist_example_statuses)

          expect { runner.run }.to raise_error(TypeError, 'boom')
        end
      end

      context 'with the per-batch filter manager reset' do
        let(:filter_manager) { instance_double(RSpec::Core::FilterManager) }

        before do
          # Exercise the real run_batch so the filter reset runs, but stub the
          # RSpec world/config internals it drives.
          allow(runner).to receive(:run_batch).and_call_original
          allow(world).to receive(:reset)
          allow(world).to receive(:announce_filters)
          allow(world).to receive(:example_count)
          allow(world).to receive_messages(ordered_example_groups: [], all_examples: [])
          allow(config).to receive(:files_or_directories_to_run=)
          allow(config).to receive(:load_spec_files)
          allow(config).to receive(:filter_manager=)
          allow(RSpec::Core::FilterManager).to receive(:new).and_return(filter_manager)
          allow(options).to receive(:configure_filter_manager)
        end

        it 'reapplies the CLI filters on a fresh filter manager for each batch' do
          expect(client).to receive(:request).and_return([{ path: '03_spec.rb' }], [])

          # Two batches: first (seed) + one requested. Each rebuilds the filter
          # manager from the options so a cleared inclusion filter cannot leak.
          expect(options).to receive(:configure_filter_manager).with(filter_manager).twice
          expect(config).to receive(:filter_manager=).with(filter_manager).twice

          runner.run
        end
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
