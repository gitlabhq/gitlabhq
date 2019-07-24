# frozen_string_literal: true

module Gitlab
  module ImportExport
    extend self

    # For every version update the version history in these docs must be kept up to date:
    # - development/import_export.md
    # - user/project/settings/import_export.md
    VERSION = '0.2.4'.freeze
    FILENAME_LIMIT = 50

    def export_path(relative_path:)
      File.join(storage_path, relative_path)
    end

    def storage_path
      File.join(Settings.shared['path'], 'tmp/project_exports')
    end

    def import_upload_path(filename:)
      File.join(storage_path, 'uploads', filename)
    end

    def project_filename
      "project.json"
    end

    def project_bundle_filename
      "project.bundle"
    end

    def lfs_objects_filename
      "lfs-objects.json"
    end

    def lfs_objects_storage
      "lfs-objects"
    end

    def config_file
      Rails.root.join('lib/gitlab/import_export/import_export.yml')
    end

    def version_filename
      'VERSION'
    end

    def export_filename(project:)
      basename = "#{Time.now.strftime('%Y-%m-%d_%H-%M-%3N')}_#{project.full_path.tr('/', '_')}"

      "#{basename[0..FILENAME_LIMIT]}_export.tar.gz"
    end

    def version
      VERSION
    end

    def reset_tokens?
      true
    end
  end
end
