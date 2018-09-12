module Gitlab
  module Kubernetes
    module Helm
      HELM_VERSION = '2.7.2'.freeze
      KUBECTL_VERSION = 'v1.11.0'
      NAMESPACE = 'gitlab-managed-apps'.freeze
      SERVICE_ACCOUNT = 'tiller'.freeze
      CLUSTER_ROLE_BINDING = 'tiller-admin'.freeze
      CLUSTER_ROLE = 'cluster-admin'.freeze
    end
  end
end
