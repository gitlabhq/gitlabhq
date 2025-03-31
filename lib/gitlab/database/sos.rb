# frozen_string_literal: true

# WIP
module Gitlab
  module Database
    module Sos
      DURATION = 5.minutes
      SAMPLING_INTERVAL = 3.seconds

      SINGLE_TASKS = [
        Sos::ArSchemaDump,
        Sos::DbStatsActivity
      ].freeze

      LONG_RUNNING_TASKS = [
        Sos::PgStatStatements,
        Sos::DbLoopStatsActivity
      ].freeze

      def self.run(output_file)
        Output.writing(output_file, mode: :zip) do |output|
          Gitlab::Database::EachDatabase.each_connection(include_shared: false) do |conn, name|
            SINGLE_TASKS.each do |t|
              t.new(conn, name, output).run
            end
          end

          duration = DURATION.from_now

          while duration.future?
            Gitlab::Database::EachDatabase.each_connection(include_shared: false) do |conn, name|
              LONG_RUNNING_TASKS.each do |t|
                t.new(conn, name, output).run
              end
            end
            sleep(SAMPLING_INTERVAL)
          end
        end
      end
    end
  end
end
