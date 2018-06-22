module Pseudonymizer
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
      return @output_files unless @output_files.empty?

      tables = config[:tables]
      FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)

      @output_files = tables.map do |k, v|
        table_to_csv(k, v[:whitelist], v[:pseudo])
      end.compact

      schema_to_yml
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
      filter = Filter.new(table, whitelist_columns, pseudonymity_columns)
      pager = Pager.new(table, whitelist_columns)

      Enumerator.new do |yielder|
        pager.pages do |page|
          filter.anonymize(page).each do |result|
            yielder << result
          end
        end
      end.lazy
    end

    def table_to_schema(table)
      table_config = @config.dig(:tables, table)

      type_results = ActiveRecord::Base.connection.columns(table)
      type_results = type_results.select do |c|
        table_config[:whitelist].include?(c.name)
      end

      type_results = type_results.map do |c|
        data_type = c.sql_type

        if table_config[:pseudo].include?(c.name)
          data_type = "character varying"
        end

        { name: c.name, data_type: data_type }
      end

      set_schema_column_types(table, type_results)
    end

    def set_schema_column_types(table, type_results)
      has_id = type_results.any? {|c| c[:name] == "id" }

      type_results.each do |type_result|
        @schema[table.to_s][type_result[:name]] = type_result[:data_type]
      end

      if has_id
        # if there is an ID, it is the mapping_key
        @schema[table.to_s]["gl_mapping_key"] = "id"
      end
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
