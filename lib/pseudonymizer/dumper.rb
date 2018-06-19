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

            result[field] = OpenSSL::HMAC.hexdigest(digest, key, String(result[field]))
          end
          yielder << result
        end
      end
    end
  end

  class Dumper
    attr_accessor :config, :output_dir

    def initialize(options)
      @config = options.config.deep_symbolize_keys
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

      tables = config[:tables]
      FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)

      schema_to_yml
      @output_files = tables.map do |k, v|
        table_to_csv(k, v[:whitelist], v[:pseudo])
      end.compact

      file_list_to_json
      @output_files
    end

    private

    def output_filename(basename = nil, ext = "csv.gz")
      File.join(output_dir, "#{basename}.#{ext}")
    end

    def schema_to_yml
      file_path = output_filename("schema", "yml")
      File.write(file_path, @schema.to_yaml)
    end

    def file_list_to_json
      file_path = output_filename("file_list", "json")
      relative_files = @output_files.map(&File.method(:basename))
      File.write(file_path, relative_files.to_json)
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
      whitelisted = ->(table) { @config.dig(:tables, table, :whitelist) }
      pseudonymized = ->(table) { @config.dig(:tables, table, :pseudo) }

      type_results = ActiveRecord::Base.connection.columns(table)
      type_results = type_results.select do |c|
        whitelisted[table].include?(c.name)
      end

      type_results = type_results.map do |c|
        data_type = c.sql_type

        if pseudonymized[table].include?(c.name)
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
      file_path = output_filename(table)
      headers = contents.peek.keys

      Rails.logger.info "#{self.class.name} writing #{table} to #{file_path}."
      Zlib::GzipWriter.open(file_path) do |io|
        csv = CSV.new(io, headers: headers, write_headers: true)
        contents.each { |row| csv << row.values }
      end

      file_path
    rescue StopIteration
      Rails.logger.info "#{self.class.name} table #{table} is empty."
      nil
    end
  end
end
