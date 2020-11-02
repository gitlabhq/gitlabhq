# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class TestCase
        STATUS_SUCCESS = 'success'
        STATUS_FAILED = 'failed'
        STATUS_SKIPPED = 'skipped'
        STATUS_ERROR = 'error'
        STATUS_TYPES = [STATUS_ERROR, STATUS_FAILED, STATUS_SUCCESS, STATUS_SKIPPED].freeze

        attr_reader :suite_name, :name, :classname, :execution_time, :status, :file, :system_output, :stack_trace, :key, :attachment, :job, :recent_failures

        def initialize(params)
          @suite_name = params.fetch(:suite_name)
          @name = params.fetch(:name)
          @classname = params.fetch(:classname)
          @file = params.fetch(:file, nil)
          @execution_time = params.fetch(:execution_time).to_f
          @status = params.fetch(:status)
          @system_output = params.fetch(:system_output, nil)
          @stack_trace = params.fetch(:stack_trace, nil)
          @attachment = params.fetch(:attachment, nil)
          @job = params.fetch(:job, nil)

          @recent_failures = nil

          @key = hash_key("#{suite_name}_#{classname}_#{name}")
        end

        def set_recent_failures(count, base_branch)
          @recent_failures = { count: count, base_branch: base_branch }
        end

        def has_attachment?
          attachment.present?
        end

        def attachment_url
          return unless has_attachment?

          Rails.application.routes.url_helpers.file_project_job_artifacts_path(
            job.project,
            job.id,
            attachment
          )
        end

        private

        def hash_key(key)
          Digest::SHA256.hexdigest(key)
        end
      end
    end
  end
end
