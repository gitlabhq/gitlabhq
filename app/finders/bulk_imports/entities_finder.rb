# frozen_string_literal: true

module BulkImports
  class EntitiesFinder
    def initialize(user:, bulk_import: nil, status: nil)
      @user = user
      @bulk_import = bulk_import
      @status = status
    end

    def execute
      ::BulkImports::Entity
        .preload(:failures) # rubocop: disable CodeReuse/ActiveRecord
        .by_user_id(user.id)
        .then(&method(:filter_by_bulk_import))
        .then(&method(:filter_by_status))
    end

    private

    attr_reader :user, :bulk_import, :status

    def filter_by_bulk_import(entities)
      return entities unless bulk_import

      entities.where(bulk_import_id: bulk_import.id) # rubocop: disable CodeReuse/ActiveRecord
    end

    def filter_by_status(entities)
      return entities unless ::BulkImports::Entity.all_human_statuses.include?(status)

      entities.with_status(status)
    end
  end
end
