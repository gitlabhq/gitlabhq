# frozen_string_literal: true

module Prometheus
  class CleanupMultiprocDirService
    include Gitlab::Utils::StrongMemoize

    def execute
      FileUtils.rm_rf(old_metrics) if old_metrics
    end

    private

    def old_metrics
      strong_memoize(:old_metrics) do
        Dir[File.join(multiprocess_files_dir, '*.db')] if multiprocess_files_dir
      end
    end

    def multiprocess_files_dir
      ::Prometheus::Client.configuration.multiprocess_files_dir
    end
  end
end
