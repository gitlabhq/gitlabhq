# frozen_string_literal: true

module Gitlab
  module Database
    GitlabSchemaInfo = Struct.new(
      :name,
      :description,
      :allow_cross_joins,
      :allow_cross_transactions,
      :allow_cross_foreign_keys,
      :file_path,
      :require_sharding_key,
      keyword_init: true
    ) do
      def initialize(*)
        super
        self.name = name.to_sym
        self.allow_cross_joins = add_table_specific_allows(
          :joins, convert_array_to_hash(allow_cross_joins))
        self.allow_cross_transactions = add_table_specific_allows(
          :transactions, convert_array_to_hash(allow_cross_transactions))
        self.allow_cross_foreign_keys = add_table_specific_allows(
          :foreign_keys, convert_array_to_hash(allow_cross_foreign_keys))
      end

      def self.load_file(yaml_file)
        content = YAML.load_file(yaml_file)
        new(**content.deep_symbolize_keys.merge(file_path: yaml_file))
      end

      def allow_cross_joins?(table_schemas, all_tables)
        allowed_for?(allow_cross_joins, table_schemas, all_tables)
      end

      def allow_cross_transactions?(table_schemas, all_tables)
        allowed_for?(allow_cross_transactions, table_schemas, all_tables)
      end

      def allow_cross_foreign_keys?(table_schemas, all_tables)
        allowed_for?(allow_cross_foreign_keys, table_schemas, all_tables)
      end

      private

      def allowed_for?(allowed_schemas, table_schemas, all_tables)
        # Take all the schemas in the query and remove the current schema and all the allowed schemas. If there is
        # anything left then it's not allowed. Then we even if there is nothing left we continue to verify
        # `specific_tables` used in the allowed schemas.
        denied_schemas = table_schemas - [name]
        denied_schemas -= allowed_schemas.keys
        return false unless denied_schemas.empty?

        # Additional validation for specific_tables. We should validate that if `specific_tables` is set then we will
        # need all the tables to be in the the allowed specific_tables
        all_tables.all? do |table|
          table_schema = ::Gitlab::Database::GitlabSchema.table_schema!(table)
          allowed_tables = allowed_schemas[table_schema]

          # If specific tables key is nil? (not present) then we assume all tables are allowed and return true Otherwise
          # we check every table in the current query is in specific_tables list
          allowed_tables.nil? ||
            allowed_tables[:specific_tables].include?(table)
        end
      end

      # Convert from:
      # - schema_a
      # - schema_b:
      #     specific_tables:
      #     - table_b_of_schema_b
      #     - table_c_of_schema_b
      #
      # To:
      # { :schema_a => nil,
      #   :schema_b => { specific_tables : ['table_b_of_schema_b', 'table_c_of_schema_b'] }
      # }
      #
      def convert_array_to_hash(subject)
        result = {}

        subject&.each do |item|
          if item.is_a?(Hash)
            item.each do |key, value|
              result[key.to_sym] = { specific_tables: value[:specific_tables].to_set }
            end
          else
            result[item.to_sym] = nil
          end
        end

        result
      end

      # This method loops over all the `db/docs` files for every table and injects any
      # allow_cross_joins/allow_cross_transactions/allow_cross_foreign_keys into the specific_tables lists for the
      # current schema.
      def add_table_specific_allows(type, schema_allows)
        result = schema_allows
        all_table_allows(type).each do |schema_from, tables|
          # Preserve the meaning of `nil` as defined in convert_array_to_hash as a nil value means that we allow all
          # tables
          next if result.key?(schema_from) && result[schema_from].nil?

          # Now we add the table to the specific_tables list because this table specifies it is allowed in this schema
          result[schema_from] ||= { specific_tables: Set.new }
          result[schema_from][:specific_tables] += tables
        end
        result.freeze
      end

      # For the given type we iterate over all db/docs files build a Hash like:
      #
      # {
      #   gitlab_main_cell: ['table_a', 'table_b']
      # }
      #
      # This specifies that in the `gitlab_main_cell` schema the 'table_a` and `table_b` tables are allowing cross
      # queries with the current schema
      def all_table_allows(type)
        @all_table_allows ||= {}
        @all_table_allows[type] ||= begin
          result = {}
          ::Gitlab::Database::Dictionary.entries.each do |entry|
            allowed_schemas = entry.allow_cross_to_schemas(type)
            allowed_schemas.each do |schema|
              # In the context of this GitlabSchemaInfo we only need the tables that have allowed this schema
              next unless schema == name

              result[entry.gitlab_schema.to_sym] ||= []
              result[entry.gitlab_schema.to_sym] << entry.key_name
            end
          end
          result
        end
      end
    end
  end
end
