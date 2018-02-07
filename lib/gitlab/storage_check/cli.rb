module Gitlab
  module StorageCheck
    class CLI
      def self.start!(args)
        runner = new(Gitlab::StorageCheck::OptionParser.parse!(args))
        runner.start_loop
      end

      attr_reader :logger, :options

      def initialize(options)
        @options = options
        @logger = Logger.new(STDOUT)
      end

      def start_loop
        logger.info "Checking #{options.target} every #{options.interval} seconds"

        if options.dryrun
          logger.info "Dryrun, exiting..."
          return
        end

        begin
          loop do
            response = GitlabCaller.new(options).call!
            log_response(response)
            update_settings(response)

            sleep options.interval
          end
        rescue Interrupt
          logger.info "Ending storage-check"
        end
      end

      def update_settings(response)
        previous_interval = options.interval

        if response.valid?
          options.interval = response.check_interval || previous_interval
        end

        if previous_interval != options.interval
          logger.info "Interval changed: #{options.interval} seconds"
        end
      end

      def log_response(response)
        unless response.valid?
          return logger.error("Invalid response checking nfs storage: #{response.http_response.inspect}")
        end

        if response.responsive_shards.any?
          logger.debug("Responsive shards: #{response.responsive_shards.join(', ')}")
        end

        warnings = []
        if response.skipped_shards.any?
          warnings << "Skipped shards: #{response.skipped_shards.join(', ')}"
        end

        if response.failing_shards.any?
          warnings << "Failing shards: #{response.failing_shards.join(', ')}"
        end

        logger.warn(warnings.join(' - ')) if warnings.any?
      end
    end
  end
end
