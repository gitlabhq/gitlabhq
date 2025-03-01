# frozen_string_literal: true

module Gitlab
  module Database
    module Sos
      class ArSchemaDump
        attr_reader :connection, :name, :output

        def initialize(connection, name, output)
          @connection = connection
          @name = name
          @output = output
        end

        def run
          file_path = File.join(name, "#{name}_schema_dump.sql")
          output.write_file(file_path) do |f|
            File.open(f, 'w') do |file|
              connection.create_schema_dumper({}).dump(file)
            end
          end
        rescue StandardError => e
          Gitlab::AppLogger.error("Error writing schema dump for DB:#{name} with error message:#{e.message}")
        end
      end
    end
  end
end
