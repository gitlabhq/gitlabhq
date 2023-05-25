# frozen_string_literal: true

module ObjectStorage
  class DeleteStaleDirectUploadsService < BaseService
    MAX_EXEC_DURATION = 250.seconds.freeze

    def initialize; end

    def execute
      total_pending_entries = ObjectStorage::PendingDirectUpload.count
      total_deleted_stale_entries = 0

      timeout = false
      start = Time.current

      ObjectStorage::PendingDirectUpload.each do |pending_upload|
        if pending_upload.stale?
          pending_upload.delete
          total_deleted_stale_entries += 1
        end

        if (Time.current - start) > MAX_EXEC_DURATION
          timeout = true
          break
        end
      end

      success(
        total_pending_entries: total_pending_entries,
        total_deleted_stale_entries: total_deleted_stale_entries,
        execution_timeout: timeout
      )
    end
  end
end
