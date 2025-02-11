# frozen_string_literal: true

module Projects
  module ImportExport
    class RelationExportService
      include Gitlab::ImportExport::CommandLineUtil

      def initialize(relation_export, user, jid, params = {})
        @relation_export = relation_export
        @user = user
        @jid = jid
        @logger = Gitlab::Export::Logger.build
        @params = params
      end

      def execute
        relation_export.update!(status_event: :start, jid: jid)

        mkdir_p(shared.export_path)
        mkdir_p(shared.archive_path)

        if relation_saver.save
          compress_export_path
          upload_compressed_file
          relation_export.finish!
        else
          raise_error(shared.errors.join(', '))
        end

      ensure
        FileUtils.rm_rf(shared.export_path)
        FileUtils.rm_rf(shared.archive_path)
      end

      private

      attr_reader :relation_export, :user, :jid, :logger, :params

      delegate :relation, :project_export_job, to: :relation_export
      delegate :project, to: :project_export_job

      def shared
        project.import_export_shared
      end

      def relation_saver
        case relation
        when Projects::ImportExport::RelationExport::UPLOADS_RELATION
          Gitlab::ImportExport::UploadsSaver.new(project: project, shared: shared)
        when Projects::ImportExport::RelationExport::REPOSITORY_RELATION
          Gitlab::ImportExport::RepoSaver.new(exportable: project, shared: shared)
        when Projects::ImportExport::RelationExport::WIKI_REPOSITORY_RELATION
          Gitlab::ImportExport::WikiRepoSaver.new(exportable: project, shared: shared)
        when Projects::ImportExport::RelationExport::LFS_OBJECTS_RELATION
          Gitlab::ImportExport::LfsSaver.new(project: project, shared: shared)
        when Projects::ImportExport::RelationExport::SNIPPETS_REPOSITORY_RELATION
          Gitlab::ImportExport::SnippetsRepoSaver.new(project: project, shared: shared, current_user: nil)
        when Projects::ImportExport::RelationExport::DESIGN_REPOSITORY_RELATION
          Gitlab::ImportExport::DesignRepoSaver.new(exportable: project, shared: shared)
        else
          Gitlab::ImportExport::Project::RelationSaver.new(
            project: project,
            shared: shared,
            relation: relation,
            user: user,
            params: params
          )
        end
      end

      def upload_compressed_file
        upload = relation_export.build_upload
        File.open(archive_file_full_path) { |file| upload.export_file = file }
        upload.save!
      end

      def compress_export_path
        tar_czf(archive: archive_file_full_path, dir: shared.export_path)
      end

      def archive_file_full_path
        @archive_file ||= File.join(shared.archive_path, "#{relation}.tar.gz")
      end

      def raise_error(error_message)
        logger.warn(
          message: 'Project relation export failed',
          export_error: error_message,
          relation: relation_export.relation,
          project_export_job_id: project_export_job.id,
          project_name: project.name,
          project_id: project.id
        )

        raise ::Gitlab::ImportExport::Error.new, error_message
      end
    end
  end
end
