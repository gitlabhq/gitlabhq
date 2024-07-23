# frozen_string_literal: true

module Gitlab
  module TemplateHelper
    def prepare_template_environment(file, user)
      return unless file

      params[:import_export_upload] = ImportExportUpload.new(import_file: file, user: user)
    end

    def tmp_filename
      SecureRandom.hex
    end
  end
end
