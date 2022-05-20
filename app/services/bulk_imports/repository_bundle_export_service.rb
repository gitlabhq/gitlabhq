# frozen_string_literal: true

module BulkImports
  class RepositoryBundleExportService
    FILENAME = 'project.bundle'

    def initialize(portable, export_path)
      @portable = portable
      @export_path = export_path
      @repository = portable.repository
    end

    def execute
      repository.bundle_to_disk(bundle_filepath) if repository.exists?
    end

    private

    attr_reader :portable, :export_path, :repository

    def bundle_filepath
      File.join(export_path, FILENAME)
    end
  end
end
