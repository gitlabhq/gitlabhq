require 'digest'
require 'csv'
require 'yaml'

module Pseudonymity
  class Anon
    def initialize(fields)
      @anon_fields = fields
    end

    def anonymize(results)
      columns = results.columns # Assume they all have the same table
      to_filter = @anon_fields & columns

      results.each do |result|
        to_filter.each do |field|
          result[field] = Digest::SHA2.new(256).hexdigest(result[field]) unless result[field].nil?
        end
      end

      results
    end
  end

  class Table

    config = {}

    def initialize
      parse_config
    end

    def tables_to_csv
      tables = @config["tables"]

      tables.map do | k, v |
        table_to_csv(k, v["whitelist"], v["anon"])
      end
    end

    def table_to_csv(table, whitelist_columns, pseudonymity_columns)
      sql = "SELECT #{whitelist_columns.join(",")} from #{table}"
      results = ActiveRecord::Base.connection.exec_query(sql)
      anon = Anon.new(pseudonymity_columns)
      results = anon.anonymize results
      write_to_csv_file table, results
    end

    def parse_config
      @config = YAML.load_file('./lib/assets/pseudonymity_dump.yml')
    end

    def write_to_csv_file(title, contents)
      file_path = "/tmp/#{title}.csv"
      if contents.empty?
        File.open(file_path, "w") {}
        return file_path
      end
      column_names = contents.first.keys
      contents = CSV.generate do | csv |
        csv << column_names
        contents.each do |x|
          csv << x.values
        end
      end
      File.open(file_path, 'w') { |file| file.write(contents) }
      return file_path
    end

    private :write_to_csv_file
  end
end