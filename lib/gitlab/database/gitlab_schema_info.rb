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
      :disallow_sequences,
      :sharding_root_tables,
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
        allowed_for?(allow_cross_joins, table_schemas, all_tables)
      end

      def allow_cross_transactions?(table_schemas, all_tables)
        allowed_for?(allow_cross_transactions, table_schemas, all_tables)
      end

      def allow_cross_foreign_keys?(table_schemas, all_tables)
        allowed_for?(allow_cross_foreign_keys, table_schemas, all_tables)
      end

      private

      def allowed_for?(allowed_schemas, table_schemas, _all_tables)
        denied_schemas = table_schemas - [name]
        denied_schemas -= allowed_schemas.keys
        denied_schemas.empty?
      end

      # Convert from:
      # - schema_a
      # - schema_b
      #
      # To:
      # { :schema_a => nil,
      #   :schema_b => nil
      # }
      #
      def convert_array_to_hash(subject)
        result = {}

        subject&.each do |item|
          result[item.to_sym] = nil
        end

        result
      end
    end
  end
end
