# frozen_string_literal: true

module BulkImports
  class Error < StandardError
    def self.unsupported_gitlab_version
      self.new("Unsupported GitLab Version. Minimum Supported Gitlab Version #{BulkImport::MIN_MAJOR_VERSION}.")
    end

    def self.scope_validation_failure
      self.new("Import aborted as the provided personal access token does not have the required 'api' scope or " \
               "is no longer valid.")
    end

    def self.invalid_url
      self.new("Import aborted as it was not possible to connect to the provided GitLab instance URL.")
    end
  end
end
