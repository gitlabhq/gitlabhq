# frozen_string_literal: true

module ImportCsv
  class BaseService
    include Gitlab::Utils::StrongMemoize

    def initialize(user, project, csv_io)
      @user = user
      @project = project
      @csv_io = csv_io
      @results = { success: 0, error_lines: [], parse_error: false, preprocess_errors: {} }
    end

    PreprocessError = Class.new(StandardError)

    def execute
      process_csv
      email_results_to_user

      results
    end

    def email_results_to_user
      raise NotImplementedError
    end

    private

    attr_reader :user, :project, :csv_io, :results

    def attributes_for(row)
      raise NotImplementedError
    end

    def validate_headers_presence!(headers)
      raise NotImplementedError
    end

    def create_object_class
      raise NotImplementedError
    end

    def validate_structure!
      header_line = csv_data.lines.first
      raise CSV::MalformedCSVError.new('File is empty, no headers found', 1) if header_line.blank?

      validate_headers_presence!(header_line)
      detect_col_sep
    end

    def preprocess!
      # any logic can be added in subclasses if needed
      # hence just a no-op rather than NotImplementedError
    end

    def process_csv
      validate_structure!
      preprocess!

      with_csv_lines.each do |row, line_no|
        attributes = attributes_for(row)

        if create_object(attributes)&.persisted?
          results[:success] += 1
        else
          results[:error_lines].push(line_no)
        end
      end
    rescue ArgumentError, CSV::MalformedCSVError => e
      results[:parse_error] = true
      results[:error_lines].push(e.line_number) if e.respond_to?(:line_number)
    rescue PreprocessError
      results[:parse_error] = false
    end

    def with_csv_lines
      CSV.new(
        csv_data,
        col_sep: detect_col_sep,
        headers: true,
        header_converters: :symbol
      ).each.with_index(2)
    end

    def csv_data
      @csv_io.open(&:read).force_encoding(Encoding::UTF_8)
    end
    strong_memoize_attr :csv_data

    def detect_col_sep
      header = csv_data.lines.first

      if header.include?(",")
        ","
      elsif header.include?(";")
        ";"
      elsif header.include?("\t")
        "\t"
      else
        raise CSV::MalformedCSVError.new('Invalid CSV format', 1)
      end
    end
    strong_memoize_attr :detect_col_sep

    def create_object(attributes)
      # default_params can be extracted into a method if we need
      # to support creation of objects that belongs to groups.
      default_params = { container: project,
                         current_user: user,
                         params: attributes,
                         perform_spam_check: false }

      create_service = create_object_class.new(**default_params.merge(extra_create_service_params))

      create_service.execute_without_rate_limiting
    end

    # Overidden in subclasses to support specific parameters
    def extra_create_service_params
      {}
    end
  end
end
