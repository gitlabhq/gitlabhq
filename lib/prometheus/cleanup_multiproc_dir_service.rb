# frozen_string_literal: true

module Prometheus
  class CleanupMultiprocDirService
    def initialize(metrics_dir)
      @metrics_dir = metrics_dir
    end

    def execute
      return if @metrics_dir.blank?

      files_to_delete = Dir[File.join(@metrics_dir, '*.db')]
      return if files_to_delete.blank?

      FileUtils.rm_rf(files_to_delete)
    end
  end
end
