require 'openssl'
require 'digest'
require 'csv'
require 'yaml'

module Pseudonymizer
  PAGE_SIZE = 10000

  class Anon
    def initialize(fields)
      @anon_fields = fields
    end

    def anonymize(results)
      columns = results.columns # Assume they all have the same table
      to_filter = @anon_fields & columns
      key = Rails.application.secrets[:secret_key_base]
      digest = OpenSSL::Digest.new('sha256')

      Enumerator.new do |yielder|
        results.each do |result|
          to_filter.each do |field|
            next if result[field].nil?

            result[field] = OpenSSL::HMAC.hexdigest(digest, key, result[field])
          end
          yielder << result
        end
      end
    end
  end

  class Dumper
    attr_accessor :config, :output_dir

    def initialize(options)
      @config = options.config
      @output_dir = options.output_dir

      @schema = {}
      @output_files = []
    end

    def tables_to_csv
      tables = config["tables"]

      FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)

      schema_to_yml
      file_list_to_json

      tables.each do |k, v|
        table_to_csv(k, v['whitelist'], v['pseudo'])
      end
    end

    def get_and_log_file_name(ext, prefix = nil, filename = nil)
      file_timestamp = filename || "#{prefix}_#{Time.now.to_i}"
      file_timestamp = "#{file_timestamp}.#{ext}"
      @output_files << file_timestamp
      File.join(output_dir, file_timestamp)
    end

    def schema_to_yml
      file_path = get_and_log_file_name("yml", "schema")
      File.open(file_path, 'w') { |file| file.write(@schema.to_yaml) }
    end

    def file_list_to_json
      file_path = get_and_log_file_name("json", nil, "file_list")
      File.open(file_path, 'w') { |file| file.write(@output_files.to_json) }
    end

    def table_to_csv(table, whitelist_columns, pseudonymity_columns)
      @schema[table] = {}
      table_to_schema(table)
      write_to_csv_file(table, table_page_results(table, whitelist_columns, pseudonymity_columns))
    rescue => e
      Rails.logger.error("Failed to export #{table}: #{e}")
    end

    # yield every results, pagined, anonymized
    def table_page_results(table, whitelist_columns, pseudonymity_columns)
      anonymizer = Anon.new(pseudonymity_columns)
      page = 0

      Enumerator.new do |yielder|
        loop do
          offset = page * PAGE_SIZE
          has_more = false

          sql = "SELECT #{whitelist_columns.join(",")} FROM #{table} LIMIT #{PAGE_SIZE} OFFSET #{offset}"

          # a page of results
          results = ActiveRecord::Base.connection.exec_query(sql)
          anonymizer.anonymize(results).each do |result|
            has_more = true
            yielder << result
          end

          raise StopIteration unless has_more

          page += 1
        end
      end.lazy
    end

    def table_to_schema(table)
      type_results = ActiveRecord::Base.connection.columns(table)
      type_results = type_results.select do |c|
        @config["tables"][table]["whitelist"].include?(c.name)
      end

      type_results = type_results.map do |c|
        data_type = c.sql_type

        if @config["tables"][table]["pseudo"].include?(c.name)
          data_type = "character varying"
        end

        { name: c.name, data_type: data_type }
      end
      set_schema_column_types(table, type_results)
    end

    def set_schema_column_types(table, type_results)
      type_results.each do |type_result|
        @schema[table][type_result[:name]] = type_result[:data_type]
      end
      # hard coded because all mapping keys in GL are id
      @schema[table]["gl_mapping_key"] = "id"
    end

    def write_to_csv_file(title, contents)
      Rails.logger.info "Writing #{title} ..."
      file_path = get_and_log_file_name("csv", title)

      CSV.open(file_path, 'w') do |csv|
        contents.with_index do |row, i|
          csv << row.keys if i == 0 # header
          csv << row.values
          csv.flush if i % PAGE_SIZE
        end
      end

      file_path
    end

    private :write_to_csv_file
  end
end
