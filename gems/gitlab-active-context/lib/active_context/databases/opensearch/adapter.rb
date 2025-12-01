# frozen_string_literal: true

module ActiveContext
  module Databases
    module Opensearch
      class Adapter
        include ActiveContext::Databases::Concerns::Adapter

        def name
          'opensearch'
        end

        def client_klass
          ActiveContext::Databases::Opensearch::Client
        end

        def indexer_klass
          ActiveContext::Databases::Opensearch::Indexer
        end

        def executor_klass
          ActiveContext::Databases::Opensearch::Executor
        end

        def indexer_connection_options
          { url: normalize_urls(options[:url]) }.merge(aws_connection_options)
        end

        private

        def aws_connection_options
          return {} unless options[:aws]

          options.slice(
            :aws, :aws_region, :aws_access_key, :aws_secret_access_key, :aws_role_arn, :client_request_timeout
          ).compact
        end
      end
    end
  end
end
