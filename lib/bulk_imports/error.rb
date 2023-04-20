# frozen_string_literal: true

module BulkImports
  class Error < StandardError
    def self.unsupported_gitlab_version
      self.new("Unsupported GitLab version. Minimum supported version is #{BulkImport::MIN_MAJOR_VERSION}.")
    end

    def self.scope_validation_failure
      self.new("Personal access token does not have the required " \
               "'api' scope or is no longer valid.")
    end

    def self.invalid_url
      self.new("Invalid source URL. Enter only the base URL of the source GitLab instance.")
    end

    def self.destination_namespace_validation_failure(destination_namespace)
      self.new("Import failed. Destination '#{destination_namespace}' is invalid, or you don't have permission.")
    end

    def self.destination_slug_validation_failure
      self.new("Import failed. Destination URL " \
               "#{Gitlab::Regex.oci_repository_path_regex_message}")
    end

    def self.destination_full_path_validation_failure(full_path)
      self.new("Import failed. '#{full_path}' already exists. Change the destination and try again.")
    end

    def self.setting_not_enabled
      self.new("Group import disabled on source or destination instance. " \
               "Ask an administrator to enable it on both instances and try again."
              )
    end
  end
end
