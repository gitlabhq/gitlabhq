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

      Enumerator.new do | yielder |
        results.each do |result|
          to_filter.each do |field|
            result[field] = Digest::SHA2.new(256).hexdigest(result[field]) unless result[field].nil?
          end
          yielder << result
        end
      end
    end
  end

  class Table
    def initialize
      @config = {}
      @csv_output = ""
      parse_config
    end

    def tables_to_csv
      tables = @config["tables"]
      @csv_output = @config["output"]["csv"]
      if not File.directory?(@csv_output)
        puts "No such directory #{@csv_output}"
        return
      end
      tables.map do | k, v |
        table_to_csv(k, v["whitelist"], v["pseudo"])
      end
    end

    def table_to_csv(table, whitelist_columns, pseudonymity_columns)
      sql = "SELECT #{whitelist_columns.join(",")} from #{table}"
      results = ActiveRecord::Base.connection.exec_query(sql)
      return if results.empty?

      anon = Anon.new(pseudonymity_columns)
      write_to_csv_file(table, anon.anonymize(results))
    end

    def parse_config
      @config = YAML.load_file('./lib/assets/pseudonymity_dump.yml')
    end

    def write_to_csv_file(title, contents)
      file_path = "#{@csv_output}/#{title}_#{Time.now.to_i}.csv"
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