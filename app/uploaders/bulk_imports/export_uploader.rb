# frozen_string_literal: true

module BulkImports
  class ExportUploader < ImportExportUploader
    EXTENSION_WHITELIST = %w[ndjson.gz].freeze
  end
end
