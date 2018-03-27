module Clusters
  module Providers
    class Gcp < ActiveRecord::Base
      self.table_name = 'cluster_providers_gcp'

      belongs_to :cluster, inverse_of: :provider_gcp, class_name: 'Clusters::Cluster'

      default_value_for :zone, 'us-central1-a'
      default_value_for :num_nodes, 3
      default_value_for :machine_type, 'n1-standard-2'

      attr_encrypted :access_token,
        mode: :per_attribute_iv,
        key: Gitlab::Application.secrets.db_key_base,
        algorithm: 'aes-256-cbc'

      validates :gcp_project_id,
        length: 1..63,
        format: {
          with: Gitlab::Regex.kubernetes_namespace_regex,
          message: Gitlab::Regex.kubernetes_namespace_regex_message
        }

      validates :zone, presence: true

      validates :num_nodes,
        presence: true,
        numericality: {
          only_integer: true,
          greater_than: 0
        }

      state_machine :status, initial: :scheduled do
        state :scheduled, value: 1
        state :creating, value: 2
        state :created, value: 3
        state :errored, value: 4

        event :make_creating do
          transition any - [:creating] => :creating
        end

        event :make_created do
          transition any - [:created] => :created
        end

        event :make_errored do
          transition any - [:errored] => :errored
        end

        before_transition any => [:errored, :created] do |provider|
          provider.access_token = nil
          provider.operation_id = nil
        end

        before_transition any => [:creating] do |provider, transition|
          operation_id = transition.args.first
          raise ArgumentError.new('operation_id is required') unless operation_id.present?

          provider.operation_id = operation_id
        end

        before_transition any => [:errored] do |provider, transition|
          status_reason = transition.args.first
          provider.status_reason = status_reason if status_reason
        end
      end

      def on_creation?
        scheduled? || creating?
      end

      def api_client
        return unless access_token

        @api_client ||= GoogleApi::CloudPlatform::Client.new(access_token, nil)
      end
    end
  end
end
