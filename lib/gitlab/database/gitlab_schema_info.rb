# frozen_string_literal: true

module Gitlab
  module Database
    GitlabSchemaInfoAllowCross = Struct.new(
      :specific_tables,
      keyword_init: true
    )

    GitlabSchemaInfo = Struct.new(
      :name,
      :description,
      :allow_cross_joins,
      :allow_cross_transactions,
      :allow_cross_foreign_keys,
      :file_path,
      :cell_local,
      keyword_init: true
    ) do
      def initialize(*)
        super
        self.name = name.to_sym
        self.allow_cross_joins = convert_array_to_hash(allow_cross_joins)
        self.allow_cross_transactions = convert_array_to_hash(allow_cross_transactions)
        self.allow_cross_foreign_keys = convert_array_to_hash(allow_cross_foreign_keys)
      end

      def self.load_file(yaml_file)
        content = YAML.load_file(yaml_file)
        new(**content.deep_symbolize_keys.merge(file_path: yaml_file))
      end

      def allow_cross_joins?(table_schemas, all_tables)
        allowed_schemas = allow_cross_joins || {}

        allowed_for?(allowed_schemas, table_schemas, all_tables)
      end

      def allow_cross_transactions?(table_schemas, all_tables)
        allowed_schemas = allow_cross_transactions || {}

        allowed_for?(allowed_schemas, table_schemas, all_tables)
      end

      def allow_cross_foreign_keys?(table_schemas, all_tables)
        allowed_schemas = allow_cross_foreign_keys || {}

        allowed_for?(allowed_schemas, table_schemas, all_tables)
      end

      private

      def allowed_for?(allowed_schemas, table_schemas, all_tables)
        denied_schemas = table_schemas - [name]
        denied_schemas -= allowed_schemas.keys
        return false unless denied_schemas.empty?

        all_tables.all? do |table|
          table_schema = ::Gitlab::Database::GitlabSchema.table_schema!(table)
          allowed_tables = allowed_schemas[table_schema]

          allowed_tables.nil? || allowed_tables.specific_tables.include?(table)
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
      #   :schema_b => { specific_tables : [:table_b_of_schema_b, :table_c_of_schema_b] }
      # }
      #
      def convert_array_to_hash(subject)
        result = {}

        subject&.each do |item|
          if item.is_a?(Hash)
            item.each do |key, value|
              result[key.to_sym] = GitlabSchemaInfoAllowCross.new(value || {})
            end
          else
            result[item.to_sym] = nil
          end
        end

        result.freeze
      end
    end
  end
end
