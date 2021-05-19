# frozen_string_literal: true

module Clusters
  module Providers
    class Aws < ApplicationRecord
      include Gitlab::Utils::StrongMemoize
      include Clusters::Concerns::ProviderStatus

      self.table_name = 'cluster_providers_aws'

      DEFAULT_REGION = 'us-east-1'

      belongs_to :cluster, inverse_of: :provider_aws, class_name: 'Clusters::Cluster'

      default_value_for :region, DEFAULT_REGION
      default_value_for :num_nodes, 3
      default_value_for :instance_type, 'm5.large'

      attr_encrypted :secret_access_key,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_32,
        algorithm: 'aes-256-gcm'

      validates :role_arn,
        length: 1..2048,
        format: {
          with: Gitlab::Regex.aws_arn_regex,
          message: Gitlab::Regex.aws_arn_regex_message
        }

      validates :num_nodes,
        numericality: {
          only_integer: true,
          greater_than: 0
        }

      validates :kubernetes_version, :key_name, :region, :instance_type, :security_group_id, length: { in: 1..255 }
      validates :subnet_ids, presence: true

      def nullify_credentials
        assign_attributes(
          access_key_id: nil,
          secret_access_key: nil,
          session_token: nil
        )
      end

      def api_client
        strong_memoize(:api_client) do
          ::Aws::CloudFormation::Client.new(credentials: credentials, region: region)
        end
      end

      def credentials
        strong_memoize(:credentials) do
          ::Aws::Credentials.new(access_key_id, secret_access_key, session_token)
        end
      end

      def has_rbac_enabled?
        true
      end

      def knative_pre_installed?
        false
      end

      def created_by_user
        cluster.user
      end
    end
  end
end
