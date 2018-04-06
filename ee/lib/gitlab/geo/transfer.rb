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

      # Returns number of bytes downloaded or -1 if unsuccessful.
      def download_from_primary
        return unless Gitlab::Geo.secondary?
        return if File.directory?(filename)

        primary = Gitlab::Geo.primary_node

        return unless primary

        url = primary.geo_transfers_url(file_type, file_id.to_s)
        req_headers = TransferRequest.new(request_data).headers

        return unless ensure_path_exists

        download_file(url, req_headers)
      end

      private

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

        return unless temp_file

        begin
          response = Gitlab::HTTP.get(url, allow_local_requests: true, headers: req_headers, stream_body: true) do |fragment|
            temp_file.write(fragment)
          end

          temp_file.flush

          unless response.success?
            log_error("Unsuccessful download", filename: filename, response_code: response.code, response_msg: response.msg, url: url)
            return file_size
          end

          if File.directory?(filename)
            log_error("Destination file is a directory", filename: filename)
            return file_size
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

        file_size
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
