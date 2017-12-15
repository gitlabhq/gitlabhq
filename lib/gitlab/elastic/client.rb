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
        base_config = {
          urls: config[:url],
          randomize_hosts: true,
          retry_on_failure: true
        }

        if config[:aws]
          creds = resolve_aws_credentials(config)
          region = config[:aws_region]

          ::Elasticsearch::Client.new(base_config) do |fmid|
            fmid.request(:aws_signers_v4, credentials: creds, service_name: 'es', region: region)
          end
        else
          ::Elasticsearch::Client.new(base_config)
        end
      end

      def self.resolve_aws_credentials(config)
        # Resolve credentials in order
        # 1.  Static config
        # 2.  ec2 instance profile
        static_credentials = Aws::Credentials.new(config[:aws_access_key], config[:aws_secret_access_key])

        return static_credentials if static_credentials&.set?

        # Instantiating this will perform an API call, so only do so if the
        # static credentials did not work
        instance_credentials = Aws::InstanceProfileCredentials.new

        instance_credentials if instance_credentials&.set?
      end
    end
  end
end
