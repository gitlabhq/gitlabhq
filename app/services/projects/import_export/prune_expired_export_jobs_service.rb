# frozen_string_literal: true

module Projects
  module ImportExport
    class PruneExpiredExportJobsService
      BATCH_SIZE = 1000

      class << self
        def execute
          delete_uploads_for_expired_jobs
          delete_expired_jobs
        end

        private

        def delete_expired_jobs
          loop do
            deleted_count = ProjectExportJob.prunable.limit(BATCH_SIZE).delete_all
            break if deleted_count == 0
          end
        end

        def delete_uploads_for_expired_jobs
          prunable_scope = ProjectExportJob.prunable.select(:id, :updated_at)
          iterator = Gitlab::Pagination::Keyset::Iterator.new(scope: prunable_scope.order_by_updated_at)

          iterator.each_batch(of: BATCH_SIZE) do |prunable_job_batch_scope|
            prunable_job_batch = prunable_job_batch_scope.to_a

            loop do
              prunable_uploads = uploads_for_expired_jobs(prunable_job_batch)
              prunable_upload_keys = prunable_uploads.begin_fast_destroy

              deleted_count = prunable_uploads.delete_all

              break if deleted_count == 0

              Upload.finalize_fast_destroy(prunable_upload_keys)
            end
          end
        end

        def uploads_for_expired_jobs(prunable_jobs)
          prunable_export_uploads = Projects::ImportExport::RelationExportUpload
            .for_project_export_jobs(prunable_jobs.map(&:id))

          Upload.for_model_type_and_id(
            Projects::ImportExport::RelationExportUpload,
            prunable_export_uploads.select(:id)
          )
        end
      end
    end
  end
end
