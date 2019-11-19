# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      HELM_VERSION = '2.16.1'
      KUBECTL_VERSION = '1.13.12'
      NAMESPACE = 'gitlab-managed-apps'
      SERVICE_ACCOUNT = 'tiller'
      CLUSTER_ROLE_BINDING = 'tiller-admin'
      CLUSTER_ROLE = 'cluster-admin'
    end
  end
end
