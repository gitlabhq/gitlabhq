# frozen_string_literal: true

module QA
  module Specs
    module Helpers
      class FastQuarantine
        include Support::API

        class << self
          def configure!
            return if Runtime::Env.dry_run
            return unless ENV["CI"]
            return if ENV["FAST_QUARANTINE"] == "false"
            return if ENV["CI_MERGE_REQUEST_LABELS"]&.include?("pipeline:run-flaky-tests")

            Runtime::Logger.debug("Running fast quarantine setup")
            setup = new
            setup.fetch_fq_file
            setup.configure_rspec
          rescue StandardError => e
            Runtime::Logger.error("Failed to setup FastQuarantine, error: '#{e.class} - #{e.message}'")
          end
        end

        private_class_method :new

        def initialize
          @logger = Runtime::Logger.logger
          @fq_filename = "fast_quarantine-gitlab.txt"
          @fq_download_filename = ENV['RSPEC_FAST_QUARANTINE_FILE'] || @fq_filename
        end

        # Fetch and save fast quarantine file
        #
        # @return [void]
        def fetch_fq_file
          download_fast_quarantine
        end

        # Configure rspec
        #
        # @return [void]
        def configure_rspec
          # Shared tooling that adds relevant rspec configuration
          require_relative '../../../../spec/support/fast_quarantine'
        end

        private

        attr_reader :logger, :fq_filename, :fq_download_filename

        # Force path to be relative to ruby process in order to avoid issues when dealing with different execution
        #   contexts of qa docker container and CI runner environment
        def fq_path
          @fq_path ||= ENV["RSPEC_FAST_QUARANTINE_PATH"] = File.join(Runtime::Path.qa_root, "tmp", fq_filename)
        end

        def download_fast_quarantine
          logger.debug("  downloading fast quarantine file")
          response = get(
            "https://gitlab-org.gitlab.io/quality/engineering-productivity/fast-quarantine/rspec/#{fq_download_filename}",
            verify_ssl: true
          )
          raise "Failed to download fast quarantine file: #{response.code}" if response.code != HTTP_STATUS_OK

          logger.debug("  saving fast quarantine file to '#{fq_path}'")
          File.write(fq_path, response.body)
        end
      end
    end
  end
end
