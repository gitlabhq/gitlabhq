# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      HELM_VERSION = '2.12.3'.freeze
      KUBECTL_VERSION = '1.11.7'.freeze
      NAMESPACE = 'gitlab-managed-apps'.freeze
      SERVICE_ACCOUNT = 'tiller'.freeze
      CLUSTER_ROLE_BINDING = 'tiller-admin'.freeze
      CLUSTER_ROLE = 'cluster-admin'.freeze
    end
  end
end
