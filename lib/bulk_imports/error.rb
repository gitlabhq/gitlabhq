# frozen_string_literal: true

module BulkImports
  class Error < StandardError
    def self.unsupported_gitlab_version
      self.new("Unsupported GitLab version. Source instance must run GitLab version #{BulkImport::MIN_MAJOR_VERSION} " \
               "or later.")
    end

    def self.scope_validation_failure
      self.new("Import aborted as the provided personal access token does not have the required 'api' scope or " \
               "is no longer valid.")
    end

    def self.invalid_url
      self.new("Invalid source URL. Enter only the base URL of the source GitLab instance.")
    end

    def self.destination_full_path_validation_failure(full_path)
      self.new("Import aborted as '#{full_path}' already exists. Change the destination and try again.")
    end
  end
end
