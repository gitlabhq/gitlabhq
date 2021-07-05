# frozen_string_literal: true

module BulkImports
  class ImportsFinder
    def initialize(user:, status: nil)
      @user = user
      @status = status
    end

    def execute
      filter_by_status(user.bulk_imports)
    end

    private

    attr_reader :user, :status

    def filter_by_status(imports)
      return imports unless BulkImport.all_human_statuses.include?(status)

      imports.with_status(status)
    end
  end
end
