# frozen_string_literal: true

module BulkImports
  class EntitiesFinder
    def initialize(user:, bulk_import: nil, params: {})
      @user = user
      @bulk_import = bulk_import
      @params = params
    end

    def execute
      ::BulkImports::Entity
        .preload(:failures) # rubocop: disable CodeReuse/ActiveRecord
        .by_user_id(user.id)
        .then { |entities| filter_by_bulk_import(entities) }
        .then { |entities| filter_by_status(entities) }
        .then { |entities| sort(entities) }
    end

    private

    attr_reader :user, :bulk_import, :status

    def filter_by_bulk_import(entities)
      return entities unless bulk_import

      entities.by_bulk_import_id(bulk_import.id)
    end

    def filter_by_status(entities)
      return entities unless ::BulkImports::Entity.all_human_statuses.include?(@params[:status])

      entities.with_status(@params[:status])
    end

    def sort(entities)
      return entities unless @params[:sort]

      entities.order_by_created_at(@params[:sort])
    end
  end
end
