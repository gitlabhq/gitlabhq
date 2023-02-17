# frozen_string_literal: true

module ImportCsv
  class BaseService
    def initialize(user, project, csv_io)
      @user = user
      @project = project
      @csv_io = csv_io
      @results = { success: 0, error_lines: [], parse_error: false }
    end

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

    def process_csv
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
    end

    def with_csv_lines
      csv_data = @csv_io.open(&:read).force_encoding(Encoding::UTF_8)
      validate_headers_presence!(csv_data.lines.first)

      CSV.new(
        csv_data,
        col_sep: detect_col_sep(csv_data.lines.first),
        headers: true,
        header_converters: :symbol
      ).each.with_index(2)
    end

    def detect_col_sep(header)
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

    def create_object(attributes)
      # NOTE: CSV imports are performed by workers, so we do not have a request context in order
      # to create a SpamParams object to pass to the issuable create service.
      spam_params = nil

      # default_params can be extracted into a method if we need
      # to support creation of objects that belongs to groups.
      default_params = { container: project,
                         current_user: user,
                         params: attributes,
                         spam_params: spam_params }

      create_service = create_object_class.new(**default_params.merge(extra_create_service_params))

      create_service.execute_without_rate_limiting
    end

    # Overidden in subclasses to support specific parameters
    def extra_create_service_params
      {}
    end
  end
end
