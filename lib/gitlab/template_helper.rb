module Gitlab
  module TemplateHelper
    def prepare_template_environment(file)
      return unless file

      params[:import_export_upload] = ImportExportUpload.new(import_file: file)
    end
  end
end
