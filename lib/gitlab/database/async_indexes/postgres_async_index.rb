# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncIndexes
      class PostgresAsyncIndex < ApplicationRecord
        self.table_name = 'postgres_async_indexes'

        MAX_IDENTIFIER_LENGTH = Gitlab::Database::MigrationHelpers::MAX_IDENTIFIER_NAME_LENGTH
        MAX_DEFINITION_LENGTH = 2048

        validates :name, presence: true, length: { maximum: MAX_IDENTIFIER_LENGTH }
        validates :table_name, presence: true, length: { maximum: MAX_IDENTIFIER_LENGTH }
        validates :definition, presence: true, length: { maximum: MAX_DEFINITION_LENGTH }

        def to_s
          definition
        end
      end
    end
  end
end
