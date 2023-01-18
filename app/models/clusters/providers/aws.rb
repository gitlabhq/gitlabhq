# frozen_string_literal: true

module Clusters
  module Providers
    class Aws < ApplicationRecord
      include Gitlab::Utils::StrongMemoize
      include Clusters::Concerns::ProviderStatus

      self.table_name = 'cluster_providers_aws'

      DEFAULT_REGION = 'us-east-1'

      belongs_to :cluster, inverse_of: :provider_aws, class_name: 'Clusters::Cluster'

      attribute :region, default: DEFAULT_REGION
      attribute :num_nodes, default: 3
      attribute :instance_type, default: "m5.large"

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
