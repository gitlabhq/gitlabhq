# frozen_string_literal: true

module Gitlab
  module Database
    class UnidirectionalCopyTrigger
      def self.on_table(table_name, connection: ActiveRecord::Base.connection)
        new(table_name, connection)
      end

      def name(from_column_names, to_column_names)
        from_column_names, to_column_names = check_column_names!(from_column_names, to_column_names)

        unchecked_name(from_column_names, to_column_names)
      end

      def create(from_column_names, to_column_names, trigger_name: nil)
        from_column_names, to_column_names = check_column_names!(from_column_names, to_column_names)
        trigger_name ||= unchecked_name(from_column_names, to_column_names)

        assignment_clauses = assignment_clauses_for_columns(from_column_names, to_column_names)

        connection.execute(<<~SQL)
          CREATE OR REPLACE FUNCTION #{trigger_name}()
          RETURNS trigger AS
          $BODY$
          BEGIN
            #{assignment_clauses};
            RETURN NEW;
          END;
          $BODY$
          LANGUAGE 'plpgsql'
          VOLATILE
        SQL

        connection.execute(<<~SQL)
          DROP TRIGGER IF EXISTS #{trigger_name}
          ON #{quoted_table_name}
        SQL

        connection.execute(<<~SQL)
          CREATE TRIGGER #{trigger_name}
          BEFORE INSERT OR UPDATE
          ON #{quoted_table_name}
          FOR EACH ROW
          EXECUTE FUNCTION #{trigger_name}()
        SQL
      end

      def drop(trigger_name)
        connection.execute("DROP TRIGGER IF EXISTS #{trigger_name} ON #{quoted_table_name}")
        connection.execute("DROP FUNCTION IF EXISTS #{trigger_name}()")
      end

      private

      attr_reader :table_name, :connection

      def initialize(table_name, connection)
        @table_name = table_name
        @connection = connection
      end

      def quoted_table_name
        @quoted_table_name ||= connection.quote_table_name(table_name)
      end

      def check_column_names!(from_column_names, to_column_names)
        from_column_names = Array.wrap(from_column_names)
        to_column_names = Array.wrap(to_column_names)

        unless from_column_names.size == to_column_names.size
          raise ArgumentError, 'number of source and destination columns must match'
        end

        [from_column_names, to_column_names]
      end

      def unchecked_name(from_column_names, to_column_names)
        joined_column_names = from_column_names.zip(to_column_names).flatten.join('_')
        'trigger_' + Digest::SHA256.hexdigest("#{table_name}_#{joined_column_names}").first(12)
      end

      def assignment_clauses_for_columns(from_column_names, to_column_names)
        combined_column_names = to_column_names.zip(from_column_names)

        assignment_clauses = combined_column_names.map do |(new_name, old_name)|
          new_name = connection.quote_column_name(new_name)
          old_name = connection.quote_column_name(old_name)

          "NEW.#{new_name} := NEW.#{old_name}"
        end

        assignment_clauses.join(";\n  ")
      end
    end
  end
end
