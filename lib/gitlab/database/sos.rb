# frozen_string_literal: true

# WIP
module Gitlab
  module Database
    module Sos
      TASKS = [
        Sos::DbStatsActivity,
        Sos::PgSchemaDump
      ].freeze

      def self.run(output_file)
        Output.writing(output_file, mode: :directory) do |output|
          Gitlab::Database::EachDatabase.each_connection(include_shared: false) do |conn, name|
            TASKS.each { |t| t.new(conn, name, output).run }
          end
        end
      end
    end
  end
end
