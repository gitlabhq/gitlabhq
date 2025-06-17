# frozen_string_literal: true

require "fileutils"

module Gitlab
  module Orchestrator
    module Helpers
      module Utils
        METRICS_FILENAME = "metrics.json"

        # Global tmp dir for file operations
        #
        # @return [String]
        def self.tmp_dir
          @tmp_dir ||= Dir.mktmpdir("orchestrator")
        end

        # gitlab-orchestrator configuration directory
        #
        # @return [String]
        def self.config_dir
          @config_dir ||= File.join(Dir.home, ".gitlab-orchestrator").tap { |dir| FileUtils.mkdir_p(dir) }
        end

        # Background process PID file for metrics collector
        #
        # @return [String]
        def self.metrics_pid_file
          @metrics_pid_file ||= File.join(config_dir, "collector.pid")
        end
      end
    end
  end
end
