# frozen_string_literal: true

module Issues
  class ImportCsvService
    def initialize(user, project, upload)
      @user = user
      @project = project
      @uploader = upload.build_uploader
      @results = { success: 0, errors: [], valid_file: true }
    end

    def execute
      # Cache remote file locally for processing
      @uploader.cache_stored_file! unless @uploader.file_storage?

      process_csv
      email_results_to_user

      cleanup_cache unless @uploader.file_storage?

      @results
    end

    private

    def process_csv
      CSV.foreach(@uploader.file.path, col_sep: detect_col_sep, headers: true).with_index(2) do |row, line_no|
        issue = Issues::CreateService.new(@project, @user, title: row[0], description: row[1]).execute

        if issue.persisted?
          @results[:success] += 1
        else
          @results[:errors].push(line_no)
        end
      end
    rescue ArgumentError, CSV::MalformedCSVError
      @results[:valid_file] = false
    end

    def email_results_to_user
      Notify.import_issues_csv_email(@user.id, @project.id, @results).deliver_now
    end

    def detect_col_sep
      header = File.open(@uploader.file.path, &:readline)

      if header.include?(",")
        ","
      elsif header.include?(";")
        ";"
      elsif header.include?("\t")
        "\t"
      else
        raise CSV::MalformedCSVError
      end
    end

    def cleanup_cache
      cached_file_path = @uploader.file.cache_path

      File.delete(cached_file_path)
      Dir.delete(File.dirname(cached_file_path))
    end
  end
end
