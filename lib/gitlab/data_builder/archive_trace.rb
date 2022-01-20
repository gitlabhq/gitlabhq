# frozen_string_literal: true

module Gitlab
  module DataBuilder
    module ArchiveTrace
      extend self

      def build(job)
        {
          object_kind: 'archive_trace',
          trace_url: job.job_artifacts_trace.file.url,
          build_id: job.id,
          pipeline_id: job.pipeline_id,
          project: job.project.hook_attrs
        }
      end
    end
  end
end
