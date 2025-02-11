# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class LfsObjectsPipeline
        include Pipeline
        include IndexCacheStrategy

        file_extraction_pipeline!

        def extract(_context)
          download_service.execute
          decompression_service.execute
          extraction_service.execute

          file_paths = Dir.glob(File.join(tmpdir, '*'))

          BulkImports::Pipeline::ExtractedData.new(data: file_paths)
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def load(_context, file_path)
          Gitlab::PathTraversal.check_path_traversal!(file_path)
          Gitlab::PathTraversal.check_allowed_absolute_path!(file_path, [Dir.tmpdir])

          return if tar_filepath?(file_path)
          return if lfs_json_filepath?(file_path)
          return if File.directory?(file_path)
          return if Gitlab::Utils::FileInfo.linked?(file_path)

          size = File.size(file_path)
          oid = LfsObject.calculate_oid(file_path)

          lfs_object = LfsObject.find_or_initialize_by(oid: oid, size: size)
          lfs_object.file = File.open(file_path) unless lfs_object.file&.exists?
          lfs_object.save! if lfs_object.changed?

          repository_types(oid)&.each do |type|
            create_lfs_objects_project(lfs_object, type)
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def after_run(_)
          FileUtils.rm_rf(tmpdir)
        end

        private

        def download_service
          BulkImports::FileDownloadService.new(
            configuration: context.configuration,
            relative_url: context.entity.relation_download_url_path(relation, context.extra[:batch_number]),
            tmpdir: tmpdir,
            filename: targz_filename
          )
        end

        def decompression_service
          BulkImports::FileDecompressionService.new(tmpdir: tmpdir, filename: targz_filename)
        end

        def extraction_service
          BulkImports::ArchiveExtractionService.new(tmpdir: tmpdir, filename: tar_filename)
        end

        def lfs_json
          @lfs_json ||= Gitlab::Json.parse(File.read(lfs_json_filepath))
        rescue StandardError
          raise BulkImports::Error, 'LFS Objects JSON read failed'
        end

        def tmpdir
          @tmpdir ||= Dir.mktmpdir('bulk_imports')
        end

        def relation
          BulkImports::FileTransfer::ProjectConfig::LFS_OBJECTS_RELATION
        end

        def tar_filename
          "#{relation}.tar"
        end

        def targz_filename
          "#{tar_filename}.gz"
        end

        def lfs_json_filepath?(file_path)
          file_path == lfs_json_filepath
        end

        def tar_filepath?(file_path)
          File.join(tmpdir, tar_filename) == file_path
        end

        def lfs_json_filepath
          File.join(tmpdir, "#{relation}.json")
        end

        def create_lfs_objects_project(lfs_object, repository_type)
          return unless allowed_repository_types.include?(repository_type)

          lfs_objects_project = LfsObjectsProject.create(
            project: portable,
            lfs_object: lfs_object,
            repository_type: repository_type
          )

          return if lfs_objects_project.persisted?

          logger.warn(
            project_id: portable.id,
            message: 'Failed to save lfs objects project',
            errors: lfs_objects_project.errors.full_messages.to_sentence,
            **Gitlab::ApplicationContext.current
          )
        end

        def repository_types(oid)
          types = lfs_json[oid]

          return [] unless types
          return [] unless types.is_a?(Array)

          # only return allowed repository types
          types.uniq & allowed_repository_types
        end

        def allowed_repository_types
          @allowed_repository_types ||= LfsObjectsProject.repository_types.values.push(nil)
        end
      end
    end
  end
end
