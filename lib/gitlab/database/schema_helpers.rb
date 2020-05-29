# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaHelpers
      def create_trigger_function(name, replace: true)
        replace_clause = optional_clause(replace, "OR REPLACE")
        execute(<<~SQL)
          CREATE #{replace_clause} FUNCTION #{name}()
          RETURNS TRIGGER AS
          $$
          BEGIN
          #{yield}
          END
          $$ LANGUAGE PLPGSQL
        SQL
      end

      def create_function_trigger(name, fn_name, fires: nil)
        execute(<<~SQL)
          CREATE TRIGGER #{name}
          #{fires}
          FOR EACH ROW
          EXECUTE PROCEDURE #{fn_name}()
        SQL
      end

      def drop_function(name, if_exists: true)
        exists_clause = optional_clause(if_exists, "IF EXISTS")
        execute("DROP FUNCTION #{exists_clause} #{name}()")
      end

      def drop_trigger(table_name, name, if_exists: true)
        exists_clause = optional_clause(if_exists, "IF EXISTS")
        execute("DROP TRIGGER #{exists_clause} #{name} ON #{table_name}")
      end

      def tmp_table_name(base)
        hashed_base = Digest::SHA256.hexdigest(base).first(10)

        "#{base}_#{hashed_base}"
      end

      def object_name(table, type)
        identifier = "#{table}_#{type}"
        hashed_identifier = Digest::SHA256.hexdigest(identifier).first(10)

        "#{type}_#{hashed_identifier}"
      end

      private

      def optional_clause(flag, clause)
        flag ? clause : ""
      end
    end
  end
end
