# frozen_string_literal: true

module BulkImports
  class Error < StandardError
    def self.unsupported_gitlab_version
      self.new(format(s_("BulkImport|Unsupported GitLab version. Minimum supported version is '%{version}'."),
        version: BulkImport::MIN_MAJOR_VERSION))
    end

    def self.scope_or_url_validation_failure
      self.new(s_("BulkImport|Check that the source instance base URL and the personal access " \
                  "token meet the necessary requirements."))
    end

    def self.invalid_url
      self.new(s_("BulkImport|Invalid source URL. Enter only the base URL of the source GitLab instance."))
    end

    def self.destination_namespace_validation_failure(destination_namespace)
      self.new(format(s_("BulkImport|Import failed. Destination '%{destination}' is invalid, " \
                         "or you don't have permission."), destination: destination_namespace))
    end

    def self.destination_slug_validation_failure
      self.new(format(s_("BulkImport|Import failed. Destination URL %{url}"),
        url: Gitlab::Regex.oci_repository_path_regex_message))
    end

    def self.destination_full_path_validation_failure(full_path)
      self.new(format(s_("BulkImport|Import failed. '%{path}' already exists. Change the destination and try again."),
        path: full_path))
    end

    def self.source_full_path_validation_failure(full_path)
      self.new(format(s_("BulkImport|Import failed. '%{path}' not found."),
        path: full_path))
    end

    def self.not_authorized(full_path)
      self.new(format(s_("BulkImport|Import failed. You don't have permission to export '%{path}'."),
        path: full_path))
    end

    def self.setting_not_enabled
      self.new(s_("BulkImport|Migration by direct transfer disabled on source or destination instance. " \
                  "Ask an administrator to enable it on both instances and try again."))
    end
  end
end
