module Gitlab
  module TemplateHelper
    include Gitlab::Utils::StrongMemoize

    def prepare_template_environment(file_path)
      return unless file_path.present?

      FileUtils.mkdir_p(File.dirname(import_upload_path))
      FileUtils.copy_entry(file_path, import_upload_path)
    end

    def import_upload_path
      strong_memoize(:import_upload_path) do
        Gitlab::ImportExport.import_upload_path(filename: tmp_filename)
      end
    end

    def tmp_filename
      SecureRandom.hex
    end
  end
end
