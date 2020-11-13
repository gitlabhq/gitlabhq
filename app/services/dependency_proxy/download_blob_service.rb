# frozen_string_literal: true

module DependencyProxy
  class DownloadBlobService < DependencyProxy::BaseService
    class DownloadError < StandardError
      attr_reader :http_status

      def initialize(message, http_status)
        @http_status = http_status

        super(message)
      end
    end

    def initialize(image, blob_sha, token)
      @image = image
      @blob_sha = blob_sha
      @token = token
      @temp_file = Tempfile.new
    end

    def execute
      File.open(@temp_file.path, "wb") do |file|
        Gitlab::HTTP.get(blob_url, headers: auth_headers, stream_body: true) do |fragment|
          if [301, 302, 307].include?(fragment.code)
            # do nothing
          elsif fragment.code == 200
            file.write(fragment)
          else
            raise DownloadError.new('Non-success response code on downloading blob fragment', fragment.code)
          end
        end
      end

      success(file: @temp_file)
    rescue DownloadError => exception
      error(exception.message, exception.http_status)
    rescue Timeout::Error => exception
      error(exception.message, 599)
    end

    private

    def blob_url
      registry.blob_url(@image, @blob_sha)
    end
  end
end
