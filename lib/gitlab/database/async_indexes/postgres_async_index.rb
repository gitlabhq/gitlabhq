# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncIndexes
      class PostgresAsyncIndex < SharedModel
        include QueueErrorHandlingConcern

        self.table_name = 'postgres_async_indexes'

        # schema_name + . + table_name
        MAX_TABLE_NAME_LENGTH = (Gitlab::Database::MigrationHelpers::MAX_IDENTIFIER_NAME_LENGTH * 2) + 1
        MAX_IDENTIFIER_LENGTH = Gitlab::Database::MigrationHelpers::MAX_IDENTIFIER_NAME_LENGTH
        MAX_DEFINITION_LENGTH = 2048

        before_validation :remove_whitespaces

        validates :name, presence: true, length: { maximum: MAX_IDENTIFIER_LENGTH }
        validates :table_name, presence: true, length: { maximum: MAX_TABLE_NAME_LENGTH }
        validates :definition, presence: true, length: { maximum: MAX_DEFINITION_LENGTH }

        validate :ensure_correct_schema_and_table_name

        scope :to_create, -> { where("definition ILIKE 'CREATE%'") }
        scope :to_drop, -> { where("definition ILIKE 'DROP%'") }
        scope :ordered, -> { order(attempts: :asc, id: :asc) }

        def to_s
          definition
        end

        private

        def remove_whitespaces
          definition.strip! if definition.present?
        end

        def ensure_correct_schema_and_table_name
          return unless table_name

          schema, table, *rest = table_name.split('.')

          too_long = (table.nil? && schema.length > MAX_DEFINITION_LENGTH) || # no schema given
            # both schema and table given
            (schema.length > MAX_IDENTIFIER_LENGTH || (table && table.length > MAX_IDENTIFIER_LENGTH))

          if too_long
            errors.add(:table_name, :too_long)
          elsif rest.any?
            errors.add(:table_name, :invalid)
          end
        end
      end
    end
  end
end
