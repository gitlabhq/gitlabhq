# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      class Index
        def self.find_with_schema(full_name)
          raise ArgumentError, "Index name is not fully qualified with a schema: #{full_name}" unless full_name =~ /^\w+\.\w+$/

          schema, index = full_name.split('.')

          record = ActiveRecord::Base.connection.select_one(<<~SQL)
            SELECT
              pg_index.indisunique as is_unique,
              pg_index.indisvalid as is_valid,
              pg_indexes.indexdef as definition,
              pg_namespace.nspname as schema,
              pg_class.relname as name
            FROM pg_index
            INNER JOIN pg_class ON pg_class.oid = pg_index.indexrelid
            INNER JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
            INNER JOIN pg_indexes ON pg_class.relname = pg_indexes.indexname
            WHERE pg_namespace.nspname = #{ActiveRecord::Base.connection.quote(schema)}
            AND pg_class.relname = #{ActiveRecord::Base.connection.quote(index)}
          SQL

          return unless record

          new(OpenStruct.new(record))
        end

        delegate :definition, :schema, :name, to: :@attrs

        def initialize(attrs)
          @attrs = attrs
        end

        def unique?
          @attrs.is_unique
        end

        def valid?
          @attrs.is_valid
        end

        def to_s
          name
        end
      end
    end
  end
end
