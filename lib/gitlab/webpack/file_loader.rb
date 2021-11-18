# frozen_string_literal: true

require 'net/http'
require 'uri'

module Gitlab
  module Webpack
    class FileLoader
      class BaseError < StandardError
        attr_reader :original_error, :uri

        def initialize(uri, orig)
          super orig.message
          @uri = uri.to_s
          @original_error = orig
        end
      end

      StaticLoadError = Class.new(BaseError)
      DevServerLoadError = Class.new(BaseError)
      DevServerSSLError = Class.new(BaseError)

      def self.load(path)
        if Gitlab.config.webpack.dev_server.enabled
          self.load_from_dev_server(path)
        else
          self.load_from_static(path)
        end
      end

      def self.load_from_dev_server(path)
        host = Gitlab.config.webpack.dev_server.host
        port = Gitlab.config.webpack.dev_server.port
        scheme = Gitlab.config.webpack.dev_server.https ? 'https' : 'http'
        uri = Addressable::URI.new(scheme: scheme, host: host, port: port, path: self.dev_server_path(path))

        # localhost could be blocked via Gitlab::HTTP
        response = HTTParty.get(uri.to_s, verify: false) # rubocop:disable Gitlab/HTTParty

        return response.body if response.code == 200

        raise "HTTP error #{response.code}"
      rescue OpenSSL::SSL::SSLError, EOFError => e
        raise DevServerSSLError.new(uri, e)
      rescue StandardError => e
        raise DevServerLoadError.new(uri, e)
      end

      def self.load_from_static(path)
        file_uri = ::Rails.root.join(
          Gitlab.config.webpack.output_dir,
          path
        )

        File.read(file_uri)
      rescue StandardError => e
        raise StaticLoadError.new(file_uri, e)
      end

      def self.dev_server_path(path)
        "/#{Gitlab.config.webpack.public_path}/#{path}"
      end
    end
  end
end
