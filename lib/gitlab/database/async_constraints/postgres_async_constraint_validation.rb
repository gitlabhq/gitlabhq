# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncConstraints
      class PostgresAsyncConstraintValidation < SharedModel
        include QueueErrorHandlingConcern

        self.table_name = 'postgres_async_foreign_key_validations'

        MAX_IDENTIFIER_LENGTH = Gitlab::Database::MigrationHelpers::MAX_IDENTIFIER_NAME_LENGTH
        MAX_LAST_ERROR_LENGTH = 10_000

        validates :name, presence: true, uniqueness: { scope: :table_name }, length: { maximum: MAX_IDENTIFIER_LENGTH }
        validates :table_name, presence: true, length: { maximum: MAX_IDENTIFIER_LENGTH }

        scope :ordered, -> { order(attempts: :asc, id: :asc) }

        def self.table_available?
          connection.table_exists?(table_name)
        end
      end
    end
  end
end
