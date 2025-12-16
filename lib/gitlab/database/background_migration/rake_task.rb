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

          puts

          # Convert all elements to strings and handle nil values
          string_data = data.map { |row| row.map(&:to_s) }

          # Calculate the maximum width for each column
          column_widths = []
          string_data.each do |row|
            row.each_with_index do |cell, index|
              column_widths[index] = [column_widths[index] || 0, cell.length].max
            end
          end

          if headers
            # Print header row
            header = string_data.first
            print_row(header, column_widths)

            # Print separator line
            separator = column_widths.map { |width| '-' * width }.join('-|-')
            puts separator
          end

          # Print data rows
          start = headers ? 1 : 0
          string_data[start..].each do |row|
            print_row(row, column_widths)
          end

          puts
        end

        def print_row(row, column_widths)
          formatted_cells = row.each_with_index.map do |cell, index|
            cell.ljust(column_widths[index])
          end
          puts formatted_cells.join(' | ')
        end
        # rubocop:enable Rails/Output
      end
    end
  end
end
