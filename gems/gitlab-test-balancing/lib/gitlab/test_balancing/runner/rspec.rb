# frozen_string_literal: true

require 'gitlab/test_balancing/client'

module Gitlab
  module TestBalancing
    module Runner
      # Drives a dynamic, API-balanced RSpec run for a single parallel node.
      #
      # Seeds this node's static test split into the shared pool via the API, then
      # pulls and runs batches until the queue drains, keeping ONE reporter open
      # for the whole lane so counts, the `Failures:` block and rerun snippets
      # print once at the end.
      #
      # This class owns only the RSpec lifecycle and the queue-drain loop; it is
      # project-agnostic. The caller computes the static split (however it likes)
      # and passes it in. `#run` returns a Result and never calls `exit`, so the
      # caller controls process termination.
      #
      # Each pulled batch is driven through the full `RSpec::Core::Runner#run_specs`
      # lifecycle
      # (https://github.com/rspec/rspec-core/blob/main/lib/rspec/core/runner.rb),
      # loading the batch's files together (the server caps a claim at a small
      # number of files).
      #
      # The only deviation from `run_specs` is keeping ONE outer `reporter.report`
      # across all batches, and `with_suite_hooks` wrapping the whole lane so
      # before(:suite)/after(:suite) run once.
      class Rspec
        # status: process exit status (0 on success).
        # unavailable: true when the feature was unavailable (404)
        Result = Struct.new(:status, :unavailable, keyword_init: true) do
          def passed?
            status.zero?
          end

          def unavailable?
            unavailable
          end
        end

        NULL_LOGGER = Object.new.tap do |logger|
          def logger.info(*); end
          def logger.warn(*); end
        end

        # test_splits: array of { path:, expected_duration: } for this node.
        # rspec_args: array of RSpec CLI args;
        #   any trailing file list (after `--`) is stripped since files are supplied dynamically per batch.
        def initialize(test_splits:, rspec_args: [], client: nil, logger: NULL_LOGGER)
          @test_splits = test_splits
          @rspec_args = rspec_args
          @logger = logger
          @client = client || Client.new(logger: logger)
        end

        def run
          first_batch = seed_and_claim_first_batch
          return Result.new(status: 0, unavailable: true) if first_batch.nil?

          boot_rspec
          all_passed = drain_with_report(first_batch)

          Result.new(status: exit_code(all_passed), unavailable: false)
        ensure
          # Persist even if the run raised (e.g. a profiler blowing up during
          # teardown), so scripts can still --only-failures retry the specs that
          # actually ran. Guarded by @config so an early return/crash is safe.
          persist_example_statuses if @config
        end

        private

        attr_reader :test_splits, :rspec_args, :client, :logger

        def seed_and_claim_first_batch
          logger.info "Seeding #{test_splits.size} test splits into the test balancing pool."
          result = client.initialize_balancing(test_splits)
          logger.info "Test balancing initialized in '#{result.mode}' mode."

          result.test_splits
        rescue Client::FeatureUnavailableError
          logger.info 'Test balancing is unavailable, falling back to static split.'
          nil
        end

        def boot_rspec
          require 'rspec/core'

          @options = ::RSpec::Core::ConfigurationOptions.new(base_rspec_args)
          ::RSpec::Core::Runner.new(@options).configure($stderr, $stdout)

          @config = ::RSpec.configuration
          @world  = ::RSpec.world

          # We need to alter world.example_groups for each iteration and world.all_examples
          # only ever reflects the current batch. So we keep our own record of executed examples.
          @executed_examples = []
        end

        def drain_with_report(first_batch)
          # One report cycle for the entire lane. The true example count is unknown
          # up front (files arrive dynamically), so we pass 0 as the expected count;
          # progress/summary formatters treat this as "unknown total".
          @config.reporter.report(0) do |reporter|
            @reporter = reporter
            @config.with_suite_hooks do # before(:suite)/after(:suite) run once for the lane
              drain_queue(first_batch)
            end
          end
        end

        # Run the first batch, then keep requesting and running batches until the
        # queue is drained. Returns true when every example across every batch passed.
        #
        # Stops pulling once RSpec sets world.wants_to_quit (fail-fast limit met or
        # an interrupt), mirroring how Runner#run guards run_specs.
        def drain_queue(first_batch)
          all_passed = true
          batch = first_batch

          loop do
            all_passed = false unless run_batch(batch)

            break if @world.wants_to_quit

            batch = client.request
            break if batch.empty?
          end

          all_passed
        end

        # Run a whole pulled batch through the full `run_specs` lifecycle against
        # the shared reporter. Returns true if every example in the batch passed.
        def run_batch(batch)
          paths = batch.map { |split| split[:path] }
          expected_duration = batch.sum { |split| split[:expected_duration].to_f }
          logger.info "Pulled #{paths.size} test splits (expected duration: #{expected_duration.round(2)}s) " \
            "from queue:\n#{paths.join("\n")}"

          @world.reset

          # Setup a fresh FilterManager for every batch as
          # Rspec's announce_filters may mutate the filter manager when
          # run_all_when_everything_filtered is enabled.
          filter_manager = ::RSpec::Core::FilterManager.new
          @options.configure_filter_manager(filter_manager)
          @config.filter_manager = filter_manager

          @config.files_or_directories_to_run = paths
          @config.load_spec_files
          @world.announce_filters

          groups = @world.ordered_example_groups
          @world.example_count(groups) # force filtered_examples computation, as run_specs does

          passed = groups.map { |group| group.run(@reporter) }.all?

          # Capture this batch's examples before the next iteration's world.reset
          @executed_examples.concat(@world.all_examples)

          passed
        end

        # Mirrors RSpec::Core::Runner#exit_code: errors raised outside of examples
        # (e.g. a before(:suite) hook, or "errors occurred outside of examples")
        # fail the run even when every example passed.
        def exit_code(examples_passed)
          return @config.error_exit_code || @config.failure_exit_code if @world.non_example_failure
          return @config.failure_exit_code unless examples_passed

          0
        end

        # Reproduces RSpec::Core::Runner#persist_example_statuses, which the queue
        # loop bypasses (it never calls Runner#run). Writes the accumulated example
        # statuses to config.example_status_persistence_file_path in RSpec's native
        # format so --only-failures retries work unchanged. ExampleStatusPersister
        # merges with, and file-locks, the existing file, so a single end-of-lane
        # call is safe.
        def persist_example_statuses
          path = @config.example_status_persistence_file_path
          return if path.nil? || @executed_examples.empty?

          ::RSpec::Core::ExampleStatusPersister.persist(@executed_examples, path)
        rescue SystemCallError => e
          logger.warn "Could not write example statuses to #{path}: #{e.inspect}"
        end

        def base_rspec_args
          idx = rspec_args.index('--')
          idx ? rspec_args[0...idx] : rspec_args
        end
      end
    end
  end
end
