# frozen_string_literal: true

module BulkImports
  class FileExportService
    include Gitlab::ImportExport::CommandLineUtil

    SINGLE_OBJECT_RELATIONS = [
      FileTransfer::ProjectConfig::REPOSITORY_BUNDLE_RELATION,
      FileTransfer::ProjectConfig::DESIGN_BUNDLE_RELATION
    ].freeze

    def initialize(portable, export_path, relation, user)
      @portable = portable
      @export_path = export_path
      @relation = relation
      @user = user # not used anywhere in this class at the moment
    end

    def execute(options = {})
      export_service.execute(options)

      archive_exported_data
    end

    def export_batch(ids)
      execute(batch_ids: ids)
    end

    def exported_filename
      "#{relation}.tar"
    end

    def exported_objects_count
      case relation
      when *SINGLE_OBJECT_RELATIONS
        1
      else
        export_service.exported_objects_count
      end
    end

    private

    attr_reader :export_path, :portable, :relation

    def export_service
      @export_service ||= case relation
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
