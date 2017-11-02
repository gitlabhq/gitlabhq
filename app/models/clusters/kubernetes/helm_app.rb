module Clusters
  module Kubernetes
    class HelmApp < ActiveRecord::Base
      NAME = 'helm'.freeze

      include ::Clusters::Concerns::AppStatus
      belongs_to :kubernetes_service, class_name: 'KubernetesService', foreign_key: :service_id

      default_value_for :version, Gitlab::Clusters::Helm::HELM_VERSION

      alias_method :cluster, :kubernetes_service

      def name
        NAME
      end
    end
  end
end
