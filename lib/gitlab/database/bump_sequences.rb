# frozen_string_literal: true

module Gitlab
  module Database
    class BumpSequences
      SEQUENCE_NAME_MATCHER = /nextval\('([a-z_]+)'::regclass\)/

      # gitlab_schema: can be 'gitlab_main', 'gitlab_ci', 'gitlab_main_cell', 'gitlab_shared'
      # increase_by: positive number, to increase the sequence by
      # base_model: is to choose which connection to use to query the tables
      def initialize(gitlab_schema, increase_by, base_model = ApplicationRecord)
        @base_model = base_model
        @gitlab_schema = gitlab_schema
        @increase_by = increase_by
      end

      def execute
        sequences_by_gitlab_schema(base_model, gitlab_schema).each do |sequence_name|
          increment_sequence_by(base_model.connection, sequence_name, increase_by)
        end
      end

      private

      attr_reader :base_model, :gitlab_schema, :increase_by

      def sequences_by_gitlab_schema(base_model, gitlab_schema)
        tables = Gitlab::Database::GitlabSchema.tables_to_schema.select do |_table_name, schema_name|
          schema_name == gitlab_schema
        end.keys

        sequences = []

        tables.each do |table|
          model = Class.new(base_model) do
            self.table_name = table
          end

          model.columns.each do |column|
            match_result = column.default_function&.match(SEQUENCE_NAME_MATCHER)
            next unless match_result

            sequences << match_result[1]
          end
        end

        sequences
      end

      # This method is going to increase the sequence next_value by:
      #  - increment_by + 1 if the sequence has the attribute is_called = True (which is the common case)
      #  - increment_by if the sequence has the attribute is_called = False (for example, a newly created sequence)
      # It uses ALTER SEQUENCE as a safety mechanism to avoid that no concurrent insertions
      # will cause conflicts on the sequence.
      # This is because ALTER SEQUENCE blocks concurrent nextval, currval, lastval, and setval calls.
      def increment_sequence_by(connection, sequence_name, increment_by)
        connection.transaction do
          # The first call is to make sure that the sequence's is_called value is set to `true`
          # This guarantees that the next call to `nextval` will increase the sequence by `increment_by`
          connection.select_value("SELECT nextval($1)", nil, [sequence_name])
          connection.execute("ALTER SEQUENCE #{sequence_name} INCREMENT BY #{increment_by}")
          connection.select_value("select nextval($1)", nil, [sequence_name])
          connection.execute("ALTER SEQUENCE #{sequence_name} INCREMENT BY 1")
        end
      end
    end
  end
end
