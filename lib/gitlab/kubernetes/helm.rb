# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      HELM_VERSION = '2.16.6'
      KUBECTL_VERSION = '1.13.12'
      NAMESPACE = 'gitlab-managed-apps'
      NAMESPACE_LABELS = { 'app.gitlab.com/managed_by' => :gitlab }.freeze
      SERVICE_ACCOUNT = 'tiller'
      CLUSTER_ROLE_BINDING = 'tiller-admin'
      CLUSTER_ROLE = 'cluster-admin'

      MANAGED_APPS_LOCAL_TILLER_FEATURE_FLAG = :managed_apps_local_tiller

      def self.local_tiller_enabled?
        Feature.enabled?(MANAGED_APPS_LOCAL_TILLER_FEATURE_FLAG)
      end
    end
  end
end
