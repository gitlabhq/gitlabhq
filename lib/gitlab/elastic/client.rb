require 'elasticsearch'
require 'aws-sdk'
require 'faraday_middleware/aws_signers_v4'

module Gitlab
  module Elastic
    class BaseClient
      attr_accessor :client

      def initialize(urls)
        @urls = urls
        @client = Elasticsearch::Client.new urls: @urls
      end
    end
  end
end

module Gitlab
  module Elastic
    class AWSClient < BaseClient
      def initialize(urls, region, access_key = nil, secret_access_key = nil)
        @urls = urls
        @region = region
        @access_key = access_key
        @secret_access_key = secret_access_key

        if @access_key.nil? || @secret_access_key.nil?
          @credentials = Aws::Credentials.new()
        else
          @credentials = Aws::Credentials.new(@access_key, @secret_access_key)
        end

        @client = Elasticsearch::Client.new urls: @urls do |fmid|
          fmid.request :aws_signers_v4,
            credentials: @credentials,
            service_name: 'es',
            region: @region
        end
      end
    end
  end
end
