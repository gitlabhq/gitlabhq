# frozen_string_literal: true

module BulkImports
  class RepositoryBundleExportService
    def initialize(repository, export_path, export_filename)
      @repository = repository
      @export_path = export_path
      @export_filename = export_filename
    end

    def execute
      repository.bundle_to_disk(bundle_filepath) if repository.exists?
    end

    private

    attr_reader :repository, :export_path, :export_filename

    def bundle_filepath
      File.join(export_path, "#{export_filename}.bundle")
    end
  end
end
