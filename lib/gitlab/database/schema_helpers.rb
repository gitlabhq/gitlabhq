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

      def create_trigger(name, function_name, fires: nil)
        execute(<<~SQL)
          CREATE TRIGGER #{name}
          #{fires}
          FOR EACH ROW
          EXECUTE PROCEDURE #{function_name}()
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

      def create_comment(type, name, text)
        execute("COMMENT ON #{type} #{name} IS '#{text}'")
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

      def with_lock_retries(&block)
        Gitlab::Database::WithLockRetries.new({
          klass: self.class,
          logger: Gitlab::BackgroundMigration::Logger
        }).run(&block)
      end

      def assert_not_in_transaction_block(scope:)
        return unless transaction_open?

        raise "#{scope} operations can not be run inside a transaction block, " \
          "you can disable transaction blocks by calling disable_ddl_transaction! " \
          "in the body of your migration class"
      end

      private

      def create_range_partition(partition_name, table_name, lower_bound, upper_bound)
        execute(<<~SQL)
          CREATE TABLE #{partition_name} PARTITION OF #{table_name}
          FOR VALUES FROM (#{lower_bound}) TO (#{upper_bound})
        SQL
      end

      def optional_clause(flag, clause)
        flag ? clause : ""
      end
    end
  end
end
