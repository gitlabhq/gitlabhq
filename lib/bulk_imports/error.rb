# frozen_string_literal: true

module BulkImports
  class Error < StandardError
    def self.unsupported_gitlab_version
      self.new("Unsupported GitLab Version. Minimum Supported Gitlab Version #{BulkImport::MIN_MAJOR_VERSION}.")
    end

    def self.scope_validation_failure
      self.new("Migration aborted as the provided personal access token is no longer valid.")
    end
  end
end
