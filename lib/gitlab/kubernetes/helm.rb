# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      HELM_VERSION = '2.16.9'
      KUBECTL_VERSION = '1.13.12'
      NAMESPACE = 'gitlab-managed-apps'
      NAMESPACE_LABELS = { 'app.gitlab.com/managed_by' => :gitlab }.freeze
      SERVICE_ACCOUNT = 'tiller'
      CLUSTER_ROLE_BINDING = 'tiller-admin'
      CLUSTER_ROLE = 'cluster-admin'
    end
  end
end
