# frozen_string_literal: true

module BulkImports
  class Logger < ::Gitlab::Import::Logger
    IMPORTER_NAME = 'gitlab_migration'

    def default_attributes
      super.merge(importer: IMPORTER_NAME)
    end
  end
end
