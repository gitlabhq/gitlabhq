# frozen_string_literal: true

module Clusters
  module Gcp
    module Kubernetes
      SERVICE_ACCOUNT_NAME = 'gitlab'
      SERVICE_ACCOUNT_NAMESPACE = 'default'
      SERVICE_ACCOUNT_TOKEN_NAME = 'gitlab-token'
      CLUSTER_ROLE_BINDING_NAME = 'gitlab-admin'
      CLUSTER_ROLE_NAME = 'cluster-admin'
    end
  end
end
