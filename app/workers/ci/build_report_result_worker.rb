# frozen_string_literal: true

module Ci
  class BuildReportResultWorker
    include ApplicationWorker
    include PipelineBackgroundQueue

    tags :requires_disk_io

    idempotent!

    def perform(build_id)
      Ci::Build.find_by_id(build_id).try do |build|
        Ci::BuildReportResultService.new.execute(build)
      end
    end
  end
end
