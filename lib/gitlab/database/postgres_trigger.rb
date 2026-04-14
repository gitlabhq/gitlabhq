# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresTrigger < SharedModel
      self.table_name = 'postgres_triggers'
      self.primary_key = :identifier

      scope :by_table_name, ->(table_name, schema_name = nil) do
        if schema_name
          where(table_name: table_name, schema_name: schema_name)
        else
          where(table_name: table_name).where("schema_name = current_schema()")
        end
      end
    end
  end
end
