# This file is required by `bin/elastic_repo_indexer` as well as from within
# Rails, so needs to explicitly require its dependencies
require 'elasticsearch'
require 'aws-sdk'
require 'faraday_middleware/aws_signers_v4'

module Gitlab
  module Elastic
    module Client
      # Takes a hash as returned by `ApplicationSetting#elasticsearch_config`,
      # and configures itself based on those parameters
      def self.build(config)
        base_config = { urls: config[:url] }

        if config[:aws]
          creds = Aws::Credentials.new(config[:aws_access_key], config[:aws_secret_access_key])
          region = config[:aws_region]

          ::Elasticsearch::Client.new(base_config) do |fmid|
            fmid.request(:aws_signers_v4, credentials: creds, service_name: 'es', region: region)
          end
        else
          ::Elasticsearch::Client.new(base_config)
        end
      end
    end
  end
end
