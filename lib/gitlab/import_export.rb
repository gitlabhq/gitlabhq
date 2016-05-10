module Gitlab
  module ImportExport
    extend self

    def export_path(relative_path:)
      File.join(storage_path, relative_path)
    end

    def project_tree
      Gitlab::ImportExport::ImportExportReader.new.project_tree
    end

    def storage_path
      File.join(Settings.shared['path'], 'tmp/project_exports')
    end
  end
end
