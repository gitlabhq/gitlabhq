# frozen_string_literal: true

module Projects
  module ImportExport
    # When a project is deleted, database-level `ON DELETE CASCADE`
    # then removes all records in the hierarchy down to and including
    # `Projects::ImportExport::RelationExportUpload`. There is no FK relation
    # between `RelationExportUpload` and `Upload` records, so those must be
    # cleaned up at the code level. We can leave the other records
    # (`Projects::ImportExport::RelationExport`, etc.) intact, as they will be
    # removed by the FK cascade.
    class RemoveRelationExportUploadsService
      def initialize(project)
        @project = project
      end

      def execute
        relation_export_uploads.each_batch do |batch|
          batch.includes(:uploads).find_each do |relation_export_upload| # rubocop:disable CodeReuse/ActiveRecord -- small dataset
            # As `Projects::ImportExport::RelationExportUpload` will be removed
            # by the foreign key cascade, we can't rely on it still existing by
            # the time this job executes. Consequently, we find and pass each
            # upload ID.
            relation_export_upload.uploads.find_each do |upload|
              ::Projects::ImportExport::RemoveRelationExportUploadWorker.perform_async(upload.id)
            end
          end
        end

        ServiceResponse.success
      end

      private

      attr_reader :project

      def relation_export_uploads
        project.relation_export_uploads
      end
    end
  end
end
