# frozen_string_literal: true

module BulkImports
  module Clients
    class Graphql
      class HTTP < Graphlient::Adapters::HTTP::Adapter
        def execute(document:, operation_name: nil, variables: {}, context: {})
          response = ::Gitlab::HTTP.post(
            url,
            headers: headers,
            follow_redirects: false,
            body: {
              query: document.to_query_string,
              operationName: operation_name,
              variables: variables
            }.to_json
          )

          ::Gitlab::Json.parse(response.body)
        end
      end
      private_constant :HTTP

      attr_reader :client

      delegate :query, :parse, to: :client

      def initialize(url: Gitlab::Saas.com_url, token: nil)
        @url = Gitlab::Utils.append_path(url, '/api/graphql')
        @token = token
        @client = Graphlient::Client.new(@url, options(http: HTTP))
        @compatible_instance_version = false
      end

      def execute(*args)
        validate_instance_version!

        client.execute(*args)
      end

      def options(extra = {})
        return extra unless @token

        {
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{@token}"
          }
        }.merge(extra)
      end

      def validate_instance_version!
        return if @compatible_instance_version

        response = client.execute('{ metadata { version } }')
        version = Gitlab::VersionInfo.parse(response.data.metadata.version)

        if version.major < BulkImport::MINIMUM_GITLAB_MAJOR_VERSION
          raise ::BulkImports::Error.unsupported_gitlab_version
        else
          @compatible_instance_version = true
        end
      end
    end
  end
end
