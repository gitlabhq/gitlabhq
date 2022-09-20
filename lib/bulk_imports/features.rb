# frozen_string_literal: true

module BulkImports
  module Features
    def self.enabled?
      ::Feature.enabled?(:bulk_import)
    end
  end
end
