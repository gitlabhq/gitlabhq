# frozen_string_literal: true

module Clusters
  module Aws
    class ProxyService
      DEFAULT_REGION = 'us-east-1'

      BadRequest = Class.new(StandardError)
      Response = Struct.new(:status, :body)

      def initialize(role, params:)
        @role = role
        @params = params
      end

      def execute
        api_response = request_from_api!

        Response.new(:ok, api_response.to_hash)
      rescue *service_errors
        Response.new(:bad_request, {})
      end

      private

      attr_reader :role, :params

      def request_from_api!
        case requested_resource
        when 'key_pairs'
          ec2_client.describe_key_pairs

        when 'instance_types'
          instance_types

        when 'roles'
          iam_client.list_roles

        when 'regions'
          ec2_client.describe_regions

        when 'security_groups'
          raise BadRequest unless vpc_id.present?

          ec2_client.describe_security_groups(vpc_filter)

        when 'subnets'
          raise BadRequest unless vpc_id.present?

          ec2_client.describe_subnets(vpc_filter)

        when 'vpcs'
          ec2_client.describe_vpcs

        else
          raise BadRequest
        end
      end

      def requested_resource
        params[:resource]
      end

      def vpc_id
        params[:vpc_id]
      end

      def region
        params[:region] || DEFAULT_REGION
      end

      def vpc_filter
        {
          filters: [{
            name: "vpc-id",
            values: [vpc_id]
          }]
        }
      end

      ##
      # Unfortunately the EC2 API doesn't provide a list of
      # possible instance types. There is a workaround, using
      # the Pricing API, but instead of requiring the
      # user to grant extra permissions for this we use the
      # values that validate the CloudFormation template.
      def instance_types
        {
          instance_types: cluster_stack_instance_types.map { |type| Hash(instance_type_name: type) }
        }
      end

      def cluster_stack_instance_types
        YAML.safe_load(stack_template).dig('Parameters', 'NodeInstanceType', 'AllowedValues')
      end

      def stack_template
        File.read(Rails.root.join('vendor', 'aws', 'cloudformation', 'eks_cluster.yaml'))
      end

      def ec2_client
        ::Aws::EC2::Client.new(client_options)
      end

      def iam_client
        ::Aws::IAM::Client.new(client_options)
      end

      def credentials
        Clusters::Aws::FetchCredentialsService.new(role, region: region).execute
      end

      def client_options
        {
          credentials: credentials,
          region: region,
          http_open_timeout: 5,
          http_read_timeout: 10
        }
      end

      def service_errors
        [
          BadRequest,
          Clusters::Aws::FetchCredentialsService::MissingRoleError,
          ::Aws::Errors::MissingCredentialsError,
          ::Aws::EC2::Errors::ServiceError,
          ::Aws::IAM::Errors::ServiceError,
          ::Aws::STS::Errors::ServiceError
        ]
      end
    end
  end
end
