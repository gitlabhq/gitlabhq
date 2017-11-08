module Clusters
  module Platforms
    class Kubernetes < ActiveRecord::Base
      self.table_name = 'cluster_platforms_kubernetes'

      belongs_to :cluster, inverse_of: :platform_kubernetes, class_name: 'Clusters::Cluster'

      attr_encrypted :password,
        mode: :per_attribute_iv,
        key: Gitlab::Application.secrets.db_key_base,
        algorithm: 'aes-256-cbc'

      attr_encrypted :token,
        mode: :per_attribute_iv,
        key: Gitlab::Application.secrets.db_key_base,
        algorithm: 'aes-256-cbc'

      before_validation :enforce_namespace_to_lower_case

      validates :namespace,
        allow_blank: true,
        length: 1..63,
        format: {
          with: Gitlab::Regex.kubernetes_namespace_regex,
          message: Gitlab::Regex.kubernetes_namespace_regex_message
        }

      # We expect to be `active?` only when enabled and cluster is created (the api_url is assigned)
      validates :api_url, url: true, presence: true
      validates :token, presence: true

      # TODO: Glue code till we migrate Kubernetes Integration into Platforms::Kubernetes
      after_destroy :destroy_kubernetes_integration!

      alias_attribute :ca_pem, :ca_cert

      delegate :project, to: :cluster, allow_nil: true
      delegate :enabled?, to: :cluster, allow_nil: true

      class << self
        def namespace_for_project(project)
          "#{project.path}-#{project.id}"
        end
      end

      def actual_namespace
        if namespace.present?
          namespace
        else
          default_namespace
        end
      end

      def default_namespace
        self.class.namespace_for_project(project) if project
      end

      def kubeclient
        @kubeclient ||= kubernetes_service.kubeclient if manages_kubernetes_service?
      end

      def update_kubernetes_integration!
        raise 'Kubernetes service already configured' unless manages_kubernetes_service?

        # This is neccesary, otheriwse enabled? returns true even though cluster updated with enabled: false
        cluster.reload

        ensure_kubernetes_service&.update!(
          active: enabled?,
          api_url: api_url,
          namespace: namespace,
          token: token,
          ca_pem: ca_cert
        )
      end

      def active?
        manages_kubernetes_service?
      end

      private

      def enforce_namespace_to_lower_case
        self.namespace = self.namespace&.downcase
      end

      # TODO: glue code till we migrate Kubernetes Service into Platforms::Kubernetes class
      def manages_kubernetes_service?
        return true unless kubernetes_service&.active?

        kubernetes_service.api_url == api_url
      end

      def destroy_kubernetes_integration!
        return unless manages_kubernetes_service?

        kubernetes_service&.destroy!
      end

      def kubernetes_service
        @kubernetes_service ||= project&.kubernetes_service
      end

      def ensure_kubernetes_service
        @kubernetes_service ||= kubernetes_service || project&.build_kubernetes_service
      end
    end
  end
end
