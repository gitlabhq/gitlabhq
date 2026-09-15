# frozen_string_literal: true

require 'tty-prompt'

module Gitlab
  module Database
    module BackgroundMigration
      module RakeTask
        def connection_and_id_from_params(migration_id)
          database_name, id = migration_id.split('_')
          model = Gitlab::Database.database_base_models[database_name]

          [model.connection, id.to_i]
        end

        # rubocop:disable Rails/Output -- We do want to write to stdout
        def print_error(msg, force_exit: true)
          puts Rainbow(msg).red

          exit 1 if force_exit # rubocop:disable Rails/Exit -- used only in rake tasks
        end

        def print_message(msg, force_exit: false)
          puts Rainbow(msg).green

          exit if force_exit # rubocop:disable Rails/Exit -- used only in rake tasks
        end

        def print_table(data, headers: true)
          return if data.nil? || data.empty?

          rows = data.dup
          header_row = rows.shift if headers
          table = AsciiTable.new(rows, headers: header_row, gap: ' | ', rule_gap: '-|-')

          puts
          table.lines.each { |line| puts line }
          puts
        end
        # rubocop:enable Rails/Output
      end
    end
  end
end
