# frozen_string_literal: true

module BulkImports
  class ImportsFinder
    def initialize(user:, params: {})
      @user = user
      @params = params
    end

    def execute
      imports = filter_by_status(user.bulk_imports)
      sort(imports)
    end

    private

    attr_reader :user, :status

    def filter_by_status(imports)
      return imports unless BulkImport.all_human_statuses.include?(@params[:status])

      imports.with_status(@params[:status])
    end

    def sort(imports)
      return imports unless @params[:sort]

      imports.order_by_created_at(@params[:sort])
    end
  end
end
