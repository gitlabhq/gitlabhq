require 'digest'
require 'csv'

module Pseudonymity
  class Anon
    def initialize(fields)
      @anon_fields = fields
    end

    def anonymize(results)

      results.collect! do | r |
        new_hash = r.each_with_object({}) do | (k, v), h |
          if @anon_fields.include? k
            h[k] = Digest::SHA2.new(256).hexdigest v
          else
            h[k] = v
          end
        end
        new_hash
      end
    end
  end

  class Table
    class << self
      def table_to_csv(table, whitelist_columns, pseudonymity_columns)
        sql = "SELECT #{whitelist_columns.join(",")} from #{table}"
        results = ActiveRecord::Base.connection.exec_query(sql)
        anon = Anon.new(pseudonymity_columns)
        results = anon.anonymize results
        write_to_csv_file table, results
      end

      def write_to_csv_file(title, contents)
        file_path = "/tmp/#{title}"
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
end