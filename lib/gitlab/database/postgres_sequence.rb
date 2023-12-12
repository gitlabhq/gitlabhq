# frozen_string_literal: true

module Gitlab
  module Database
    # Backed by the postgres_sequences view
    class PostgresSequence < SharedModel
      self.primary_key = :seq_name

      scope :by_table_name, ->(table_name) { where(table_name: table_name) }
    end
  end
end
