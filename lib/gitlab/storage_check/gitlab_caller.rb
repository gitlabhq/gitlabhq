require 'excon'

module Gitlab
  module StorageCheck
    class GitlabCaller
      def initialize(options)
        @options = options
      end

      def call!
        Gitlab::StorageCheck::Response.new(get_response)
      rescue Errno::ECONNREFUSED, Excon::Error
        # Server not ready, treated as invalid response.
        Gitlab::StorageCheck::Response.new(nil)
      end

      def get_response
        scheme, *other_parts = URI.split(@options.target)
        socket_path = if  scheme == 'unix'
                        other_parts.compact.join
                      end

        connection = Excon.new(@options.target, socket: socket_path)
        connection.post(path: Gitlab::StorageCheck::ENDPOINT,
                        headers: headers)
      end

      def headers
        @headers ||= begin
                       headers = {}
                       headers['Content-Type'] = headers['Accept'] = 'application/json'
                       headers['TOKEN'] = @options.token if @options.token

                       headers
                     end
      end
    end
  end
end
