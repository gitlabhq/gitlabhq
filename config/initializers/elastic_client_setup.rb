# Be sure to restart your server when you modify this file.

require 'gitlab/current_settings'

module Elasticsearch
  module Model
    module Client
      module ClassMethods
        include Gitlab::CurrentSettings
        include Gitlab::Elastic
        def client(client = nil)
          if @client.nil? || es_configuration_changed?
            @es_url = current_application_settings.elasticsearch_url
            @es_aws = current_application_settings.elasticsearch_aws

            if @es_aws
              # AWS specific handling
              @es_region = current_application_settings.elasticsearch_aws_region
              @es_access_key = current_application_settings.elasticsearch_aws_access_key
              @es_secret_access_key = current_application_settings.elasticsearch_aws_secret_access_key
              @client = AWSClient.new(@es_url, @es_region, @es_access_key, @es_secret_access_key).client
            else
              @client = BaseClient.new(@es_url).client
            end
          end
          @client
        end

        def es_configuration_changed?
          @es_url != current_application_settings.elasticsearch_url ||
            @es_aws != current_application_settings.elasticsearch_aws
        end
      end
    end
  end
end
