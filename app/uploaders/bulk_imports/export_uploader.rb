# frozen_string_literal: true

module BulkImports
  class ExportUploader < ImportExportUploader
    EXTENSION_ALLOWLIST = %w[ndjson.gz].freeze
  end
end
