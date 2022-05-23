# frozen_string_literal: true

module BulkImports
  class FileExportService
    include Gitlab::ImportExport::CommandLineUtil

    def initialize(portable, export_path, relation)
      @portable = portable
      @export_path = export_path
      @relation = relation
    end

    def execute
      export_service.execute

      archive_exported_data
    end

    def exported_filename
      "#{relation}.tar"
    end

    private

    attr_reader :export_path, :portable, :relation

    def export_service
      case relation
      when FileTransfer::BaseConfig::UPLOADS_RELATION
        UploadsExportService.new(portable, export_path)
      when FileTransfer::ProjectConfig::LFS_OBJECTS_RELATION
        LfsObjectsExportService.new(portable, export_path)
      when FileTransfer::ProjectConfig::REPOSITORY_BUNDLE_RELATION
        RepositoryBundleExportService.new(portable.repository, export_path, relation)
      when FileTransfer::ProjectConfig::DESIGN_BUNDLE_RELATION
        RepositoryBundleExportService.new(portable.design_repository, export_path, relation)
      else
        raise BulkImports::Error, 'Unsupported relation export type'
      end
    end

    def archive_exported_data
      archive_file = File.join(export_path, exported_filename)

      tar_cf(archive: archive_file, dir: export_path)
    end
  end
end
