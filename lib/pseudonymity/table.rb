require 'openssl'
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

      Enumerator.new do |yielder|
        results.each do |result|
          to_filter.each do |field|
            secret = Rails.application.secrets[:secret_key_base]
            result[field] = OpenSSL::HMAC.hexdigest('SHA256', secret, result[field]) unless result[field].nil?
          end
          yielder << result
        end
      end
    end
  end

  class Table
    attr_accessor :config
    attr_accessor :output_dir

    def initialize
      @config = parse_config
      @output_dir = ""
      @schema = {}
      @output_files = []
    end

    def tables_to_csv
      tables = config["tables"]

      @output_dir = File.join("/tmp/", SecureRandom.hex)
      Dir.mkdir(@output_dir) unless File.directory?(@output_dir)

      new_tables = tables.map do |k, v|
        @schema[k] = {}
        table_to_csv(k, v["whitelist"], v["pseudo"])
      end

      schema_to_yml
      file_list_to_json
      new_tables
    end

    def get_and_log_file_name(ext, prefix = nil, filename = nil)
      file_timestamp = filename || "#{prefix}_#{Time.now.to_i}"
      file_timestamp = "#{file_timestamp}.#{ext}"
      @output_files << file_timestamp
      File.join(@output_dir, file_timestamp)
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
      sql = "SELECT #{whitelist_columns.join(",")} FROM #{table};"
      results = ActiveRecord::Base.connection.exec_query(sql)

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
      return if results.empty?

      anon = Anon.new(pseudonymity_columns)
      write_to_csv_file(table, anon.anonymize(results))
    end

    def set_schema_column_types(table, type_results)
      type_results.each do |type_result|
        @schema[table][type_result[:name]] = type_result[:data_type]
      end
      # hard coded because all mapping keys in GL are id
      @schema[table]["gl_mapping_key"] = "id"
    end

    def parse_config
      YAML.load_file(Rails.root.join(Gitlab.config.pseudonymizer.manifest))
    end

    def write_to_csv_file(title, contents)
      Rails.logger.info "Writing #{title} ..."
      file_path = get_and_log_file_name("csv", title)
      column_names = contents.first.keys
      contents = CSV.generate do |csv|
        csv << column_names
        contents.each do |x|
          csv << x.values
        end
      end
      File.open(file_path, 'w') { |file| file.write(contents) }
      file_path
    end

    private :write_to_csv_file
  end
end
