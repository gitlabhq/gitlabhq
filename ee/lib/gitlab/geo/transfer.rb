module Gitlab
  module Geo
    class Transfer
      include LogHelpers

      attr_reader :file_type, :file_id, :filename, :request_data

      TEMP_PREFIX = 'tmp_'.freeze

      def initialize(file_type, file_id, filename, request_data)
        @file_type = file_type
        @file_id = file_id
        @filename = filename
        @request_data = request_data
      end

      # Returns Result object with success boolean and number of bytes downloaded.
      def download_from_primary
        return failure unless Gitlab::Geo.secondary?
        return failure if File.directory?(filename)

        primary = Gitlab::Geo.primary_node

        return failure unless primary

        url = primary.geo_transfers_url(file_type, file_id.to_s)
        req_headers = TransferRequest.new(request_data).headers

        return failure unless ensure_path_exists

        download_file(url, req_headers)
      end

      class Result
        attr_reader :success, :bytes_downloaded, :primary_missing_file

        def initialize(success:, bytes_downloaded:, primary_missing_file: false)
          @success = success
          @bytes_downloaded = bytes_downloaded
          @primary_missing_file = primary_missing_file
        end
      end

      private

      def failure(primary_missing_file: false)
        Result.new(success: false, bytes_downloaded: 0, primary_missing_file: primary_missing_file)
      end

      def ensure_path_exists
        path = Pathname.new(filename)
        dir = path.dirname

        return true if File.directory?(dir)

        begin
          FileUtils.mkdir_p(dir)
        rescue => e
          log_error("unable to create directory #{dir}: #{e}")
          return false
        end

        true
      end

      # Use Gitlab::HTTP for now but switch to curb if performance becomes
      # an issue
      def download_file(url, req_headers)
        file_size = -1
        temp_file = open_temp_file(filename)

        return failure unless temp_file

        begin
          response = Gitlab::HTTP.get(url, allow_local_requests: true, headers: req_headers, stream_body: true) do |fragment|
            temp_file.write(fragment)
          end

          temp_file.flush

          unless response.success?
            log_error("Unsuccessful download", filename: filename, response_code: response.code, response_msg: response.try(:msg), url: url)
            return failure(primary_missing_file: primary_missing_file?(response, temp_file))
          end

          if File.directory?(filename)
            log_error("Destination file is a directory", filename: filename)
            return failure
          end

          FileUtils.mv(temp_file.path, filename)

          file_size = File.stat(filename).size
          log_info("Successful downloaded", filename: filename, file_size_bytes: file_size)
        rescue StandardError, Gitlab::HTTP::Error => e
          log_error("Error downloading file", error: e, filename: filename, url: url)
        ensure
          temp_file.close
          temp_file.unlink
        end

        Result.new(success: file_size > -1, bytes_downloaded: [file_size, 0].max)
      end

      def primary_missing_file?(response, temp_file)
        body = File.read(temp_file.path) if File.exist?(temp_file.path)

        if response.code == 404 && body.present?
          begin
            json_response = JSON.parse(body)
            return json_response['geo_code'] == Gitlab::Geo::FileUploader::FILE_NOT_FOUND_GEO_CODE
          rescue JSON::ParserError
          end
        end

        false
      end

      def default_permissions
        0666 - File.umask
      end

      def open_temp_file(target_filename)
        # Make sure the file is in the same directory to prevent moves across filesystems
        pathname = Pathname.new(target_filename)
        temp = Tempfile.new(TEMP_PREFIX, pathname.dirname.to_s)
        temp.chmod(default_permissions)
        temp.binmode
        temp
      rescue StandardError => e
        log_error("Error creating temporary file", error: e)
        nil
      end
    end
  end
end
