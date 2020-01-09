# frozen_string_literal: true

module Clusters
  module Aws
    class ProvisionService
      attr_reader :provider

      def execute(provider)
        @provider = provider

        configure_provider_credentials
        provision_cluster

        if provider.make_creating
          WaitForClusterCreationWorker.perform_in(
            Clusters::Aws::VerifyProvisionStatusService::INITIAL_INTERVAL,
            provider.cluster_id
          )
        else
          provider.make_errored!("Failed to update provider record; #{provider.errors.full_messages}")
        end
      rescue Clusters::Aws::FetchCredentialsService::MissingRoleError
        provider.make_errored!('Amazon role is not configured')
      rescue ::Aws::Errors::MissingCredentialsError
        provider.make_errored!('Amazon credentials are not configured')
      rescue ::Aws::STS::Errors::ServiceError => e
        provider.make_errored!("Amazon authentication failed; #{e.message}")
      rescue ::Aws::CloudFormation::Errors::ServiceError => e
        provider.make_errored!("Amazon CloudFormation request failed; #{e.message}")
      end

      private

      def provision_role
        provider.created_by_user&.aws_role
      end

      def credentials
        @credentials ||= Clusters::Aws::FetchCredentialsService.new(
          provision_role,
          provider: provider
        ).execute
      end

      def configure_provider_credentials
        provider.update!(
          access_key_id: credentials.access_key_id,
          secret_access_key: credentials.secret_access_key,
          session_token: credentials.session_token
        )
      end

      def provision_cluster
        provider.api_client.create_stack(
          stack_name: provider.cluster.name,
          template_body: stack_template,
          parameters: parameters,
          capabilities: ["CAPABILITY_IAM"]
        )
      end

      def parameters
        [
          parameter('ClusterName', provider.cluster.name),
          parameter('ClusterRole', provider.role_arn),
          parameter('ClusterControlPlaneSecurityGroup', provider.security_group_id),
          parameter('VpcId', provider.vpc_id),
          parameter('Subnets', provider.subnet_ids.join(',')),
          parameter('NodeAutoScalingGroupDesiredCapacity', provider.num_nodes.to_s),
          parameter('NodeInstanceType', provider.instance_type),
          parameter('KeyName', provider.key_name)
        ]
      end

      def parameter(key, value)
        { parameter_key: key, parameter_value: value }
      end

      def stack_template
        File.read(Rails.root.join('vendor', 'aws', 'cloudformation', 'eks_cluster.yaml'))
      end
    end
  end
end
