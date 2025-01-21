# frozen_string_literal: true

module QA
  module Support
    # Helper class to get example data based on particular run configuration
    # This is helpful when determining which examples would be executed in a particular run
    #
    class ExampleData
      class << self
        # Fetch example data for particular tag and spec combination
        #
        # @param tags [Array<String>]
        # @param specs [Array<String>]
        # @param logger [Logger]
        # @return [Array<Hash>]
        def fetch(tags, specs = nil, logger: Runtime::Logger.logger)
          logger.debug("Fetching example data for tags '#{tags}' and specs '#{specs}'")

          Tempfile.open("test-metadata.json") do |file|
            tags = tags.presence || Specs::Runner::DEFAULT_SKIPPED_TAGS
            args = [
              "--dry-run",
              "--no-color",
              "--format", QA::Support::JsonFormatter.to_s, "--out", file.path,
              *tags.flat_map { |tag| ["--tag", tag.to_s] }
            ]
            args.push("--", *(specs.presence || Specs::Runner::DEFAULT_TEST_PATH_ARGS))

            logger.debug("Executing rspec in subprocess with args: #{args.join(' ')}")
            status, output = run_rspec_subprocess(args)
            unless status.success?
              logger.error("Failed to fetch example data, subprocess output:")
              logger.error("====== BEGIN OUTPUT ======\n#{output}\n====== END OUTPUT ======")
              raise "Failed to fetch example data for tags '#{tags}' and specs '#{specs}'"
            end

            JSON.load_file(file, symbolize_names: true)[:examples]
          end
        end

        private

        # Execute rspec in a forked subprocess with dry run enabled
        #
        # @param args [Array<String>]
        # @return [Process::Status]
        def run_rspec_subprocess(args)
          Tempfile.open("output.log") do |output|
            Process.fork do
              ENV.store("QA_RSPEC_DRY_RUN", "true")

              status = RSpec::Core::Runner.run(["--out", output.path, *args])
              Kernel.exit(status)
            end
            _pid, status = Process.wait2

            [status, File.read(output.path)]
          end
        end
      end
    end
  end
end
