# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class ExportedRelationsMerger
        include Gitlab::ImportExport::CommandLineUtil

        def initialize(export_job:, shared:)
          @export_job = export_job
          @shared = shared
        end

        def save
          Dir.mktmpdir do |dirpath|
            export_job.relation_exports.each do |relation_export|
              relation = relation_export.relation
              upload = relation_export.upload
              filename = upload.export_file.filename

              tar_gz_full_path = File.join(dirpath, filename)
              decompress_path = File.join(dirpath, relation)
              Gitlab::PathTraversal.check_path_traversal!(tar_gz_full_path)
              Gitlab::PathTraversal.check_path_traversal!(decompress_path)

              # Download tar.gz
              download_or_copy_upload(
                upload.export_file, tar_gz_full_path, size_limit: relation_export.upload.export_file.size
              )

              # Decompress tar.gz
              mkdir_p(decompress_path)
              untar_zxf(dir: decompress_path, archive: tar_gz_full_path)
              File.delete(tar_gz_full_path)

              # Merge decompressed files into export_path
              RecursiveMergeFolders.merge(decompress_path, shared.export_path)
              FileUtils.rm_r(decompress_path)
            rescue StandardError => e
              shared.error(e)
              false
            end
          end

          shared.errors.empty?
        end

        private

        attr_reader :shared, :export_job

        delegate :project, to: :export_job
      end
    end
  end
end
