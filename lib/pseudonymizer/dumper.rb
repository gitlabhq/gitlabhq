require 'openssl'
require 'digest'
require 'csv'
require 'yaml'

module Pseudonymizer
  PAGE_SIZE = ENV.fetch('PSEUDONYMIZER_BATCH', 100_000)

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
      @start_at = options.start_at

      reset!
    end

    def reset!
      @schema = Hash.new { |h, k| h[k] = {} }
      @output_files = []
    end

    def tables_to_csv
      reset!

      tables = config["tables"]
      FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)

      schema_to_yml
      @output_files = tables.map do |k, v|
        table_to_csv(k, v['whitelist'], v['pseudo'])
      end
      file_list_to_json

      @output_files
    end

    private

    def output_filename(basename = nil, ext = "csv.gz")
      file_timestamp = "#{basename}.#{ext}"
      File.join(output_dir, file_timestamp)
    end

    def schema_to_yml
      file_path = output_filename("schema", "yml")
      File.open(file_path, 'w') { |file| file.write(@schema.to_yaml) }
    end

    def file_list_to_json
      file_path = output_filename("file_list", "json")
      File.open(file_path, 'w') do |file|
        relative_files = @output_files.map(&File.method(:basename))
        file.write(relative_files.to_json)
      end
    end

    def table_to_csv(table, whitelist_columns, pseudonymity_columns)
      table_to_schema(table)
      write_to_csv_file(
        table,
        table_page_results(table,
                           whitelist_columns,
                           pseudonymity_columns)
      )
    rescue => e
      Rails.logger.error("Failed to export #{table}: #{e}")
      raise e
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

    def write_to_csv_file(table, contents)
      file_path = output_filename(table, "csv.gz")

      Rails.logger.info "#{self.class.name} writing #{table} to #{file_path}."
      Zlib::GzipWriter.open(file_path) do |io|
        csv = CSV.new(io)
        contents.with_index do |row, i|
          csv << row.keys if i == 0 # header
          csv << row.values
        end
        csv.close
      end

      file_path
    end
  end
end
