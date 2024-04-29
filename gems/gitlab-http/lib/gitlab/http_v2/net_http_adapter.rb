# frozen_string_literal: true

require 'rails'
require 'net/http'
require 'webmock' if Rails.env.test?
require_relative 'buffered_io'

module Gitlab
  module HTTP_V2
    # Webmock overwrites the Net::HTTP#request method with
    # https://github.com/bblimke/webmock/blob/867f4b290fd133658aa9530cba4ba8b8c52c0d35/lib/webmock/http_lib_adapters/net_http.rb#L74
    # Net::HTTP#request usually calls Net::HTTP#connect but the Webmock overwrite doesn't.
    # This makes sure that, in a test environment, the superclass is the Webmock overwrite.
    parent_class = if defined?(WebMock) && Rails.env.test?
                     WebMock::HttpLibAdapters::NetHttpAdapter.instance_variable_get(:@webMockNetHTTP)
                   else
                     Net::HTTP
                   end

    class NetHttpAdapter < parent_class
      private

      def connect
        result = super

        @socket = BufferedIo.new(@socket.io,
          read_timeout: @socket.read_timeout,
          write_timeout: @socket.write_timeout,
          continue_timeout: @socket.continue_timeout,
          debug_output: @socket.debug_output)

        result
      end
    end
  end
end
