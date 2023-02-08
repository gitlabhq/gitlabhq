# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncIndexes
      class PostgresAsyncIndex < SharedModel
        self.table_name = 'postgres_async_indexes'

        MAX_IDENTIFIER_LENGTH = Gitlab::Database::MigrationHelpers::MAX_IDENTIFIER_NAME_LENGTH
        MAX_DEFINITION_LENGTH = 2048
        MAX_LAST_ERROR_LENGTH = 10_000

        validates :name, presence: true, length: { maximum: MAX_IDENTIFIER_LENGTH }
        validates :table_name, presence: true, length: { maximum: MAX_IDENTIFIER_LENGTH }
        validates :definition, presence: true, length: { maximum: MAX_DEFINITION_LENGTH }
        validates :last_error, length: { maximum: MAX_LAST_ERROR_LENGTH },
          if: ->(index) { index.respond_to?(:last_error) }

        scope :to_create, -> { where("definition ILIKE 'CREATE%'") }
        scope :to_drop, -> { where("definition ILIKE 'DROP%'") }
        scope :ordered, -> { order(attempts: :asc, id: :asc) }

        def to_s
          definition
        end

        def handle_exception!(error)
          transaction do
            increment!(:attempts)
            update!(last_error: format_last_error(error))
          end
        end

        private

        def format_last_error(error)
          [error.message]
            .concat(error.backtrace)
            .join("\n")
            .truncate(MAX_LAST_ERROR_LENGTH)
        end
      end
    end
  end
end
