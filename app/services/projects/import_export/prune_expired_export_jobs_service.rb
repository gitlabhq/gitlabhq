# frozen_string_literal: true

module Projects
  module ImportExport
    class PruneExpiredExportJobsService
      class << self
        def execute
          prunable_jobs = ProjectExportJob.prunable

          delete_uploads_for_expired_jobs(prunable_jobs)
          delete_expired_jobs(prunable_jobs)
        end

        private

        def delete_expired_jobs(prunable_jobs)
          prunable_jobs.each_batch do |relation|
            relation.delete_all
          end
        end

        def delete_uploads_for_expired_jobs(prunable_jobs)
          prunable_uploads = get_uploads_for_prunable_jobs(prunable_jobs)
          prunable_upload_keys = prunable_uploads.begin_fast_destroy

          prunable_uploads.each_batch do |relation|
            relation.delete_all
          end

          Upload.finalize_fast_destroy(prunable_upload_keys)
        end

        def get_uploads_for_prunable_jobs(prunable_jobs)
          prunable_export_uploads = Projects::ImportExport::RelationExportUpload
            .for_project_export_jobs(prunable_jobs.select(:id))

          Upload.for_model_type_and_id(
            Projects::ImportExport::RelationExportUpload,
            prunable_export_uploads.select(:id)
          )
        end
      end
    end
  end
end
