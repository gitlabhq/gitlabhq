# frozen_string_literal: true

require 'csv'

# Create a csv with all the pg settings

module Gitlab
  module Database
    module Sos
      class ShowAllSettings
        def self.run(output)
          query_results = ApplicationRecord.connection.execute('SHOW ALL;')

          output.write_file('pg_settings.csv') do |f|
            CSV.open(f, 'w+') do |csv|
              # headers [name, setting, description]
              csv << query_results.fields
              # data
              query_results.each do |row|
                csv << row.values
              end
            end
          end
        end
      end
    end
  end
end
