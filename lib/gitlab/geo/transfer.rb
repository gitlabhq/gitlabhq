module Gitlab
  module Geo
    class Transfer
      attr_reader :file_type, :file_id, :filename, :request_data

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

        if File.exist?(dir)
          log_transfer_error("#{dir} is not a directory, unable to save #{filename}")
          return false
        end

        begin
          FileUtils.mkdir_p(dir)
        rescue => e
          log_transfer_error("unable to create directory #{dir}: #{e}")
          return false
        end

        true
      end

      def log_transfer_error(message)
        Rails.logger.error("#{self.class.name}: #{message}")
      end

      # Use HTTParty for now but switch to curb if performance becomes
      # an issue
      def download_file(url, req_headers)
        file_size = -1

        begin
          File.open(filename, "wb") do |file|
            response = HTTParty.get(url, headers: req_headers, stream_body: true) do |fragment|
              file.write(fragment)
            end

            if response.success?
              file_size = File.stat(filename).size
              Rails.logger.info("GitLab Geo: Successfully downloaded #{filename} (#{file_size} bytes)")
            else
              log_transfer_error("Unsuccessful download: #{response.code} #{response.msg}")
            end
          end
        rescue StandardError, HTTParty::Error => e
          log_transfer_error("Error downloading file: #{e}")
        end

        file_size
      end
    end
  end
end
