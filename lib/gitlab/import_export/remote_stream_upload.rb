# frozen_string_literal: true

# This class downloads a file from one URL and uploads it to another URL
# without having to save the file on the disk and loading the whole file in
# memory. The download and upload are performed in chunks size of
# `buffer_size`. A chunk is downloaded, then uploaded, then a next chunk is
# downloaded and uploaded. This repeats until all the file is processed.

module Gitlab
  module ImportExport
    class RemoteStreamUpload
      def initialize(download_url:, upload_url:, options: {})
        @download_url = download_url
        @upload_url = upload_url
        @upload_method = options[:upload_method] || :post
        @upload_content_type = options[:upload_content_type] || 'application/gzip'
      end

      def execute
        receive_data(download_url) do |response, chunks|
          send_data(upload_url, response.content_length, chunks) do |response|
            if response.code != '200'
              raise StreamError.new("Invalid response code while uploading file. Code: #{response.code}", response.body)
            end
          end
        end
      end

      class StreamError < StandardError
        attr_reader :response_body

        def initialize(message, response_body = '')
          super(message)
          @response_body = response_body
        end
      end

      class ChunkStream
        DEFAULT_BUFFER_SIZE = 128.kilobytes

        def initialize(chunks)
          @chunks = chunks
          @last_chunk = nil
          @end_of_chunks = false
        end

        def read(n1 = nil, n2 = nil)
          ensure_chunk&.read(n1, n2)
        end

        private

        def ensure_chunk
          return @last_chunk if @last_chunk && !@last_chunk.eof?
          return if @end_of_chunks

          @last_chunk = read_next_chunk
        end

        def read_next_chunk
          next_chunk = StringIO.new

          begin
            next_chunk.write(@chunks.next) until next_chunk.size > DEFAULT_BUFFER_SIZE
          rescue StopIteration
            @end_of_chunks = true
          end

          next_chunk.rewind

          next_chunk
        end
      end

      private

      attr_reader :download_url, :upload_url, :upload_method, :upload_content_type, :logger

      def receive_data(uri)
        http = Gitlab::HTTP_V2::NewConnectionAdapter.new(URI(uri), {
          allow_local_requests: Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?,
          dns_rebind_protection: Gitlab::CurrentSettings.dns_rebinding_protection_enabled?
        }).connection

        http.start do
          request = Net::HTTP::Get.new(uri)
          http.request(request) do |response|
            if response.code == '200'
              yield(response, response.enum_for(:read_body))
            else
              raise StreamError.new(
                "Invalid response code while downloading file. Code: #{response.code}",
                response.body
              )
            end
          end
        end
      end

      def send_data(uri, content_length, chunks)
        http = Gitlab::HTTP_V2::NewConnectionAdapter.new(URI(uri), {
          allow_local_requests: Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?,
          dns_rebind_protection: Gitlab::CurrentSettings.dns_rebinding_protection_enabled?
        }).connection

        http.start do
          request = upload_request_class(upload_method).new(uri)
          request.body_stream = ChunkStream.new(chunks)
          request.content_length = content_length
          request.content_type = upload_content_type

          http.request(request) do |response|
            yield(response)
          end
        end
      end

      def upload_request_class(upload_method)
        return Net::HTTP::Put if upload_method == :put

        Net::HTTP::Post
      end
    end
  end
end
