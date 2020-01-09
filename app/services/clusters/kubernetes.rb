# frozen_string_literal: true

module Clusters
  module Kubernetes
    GITLAB_SERVICE_ACCOUNT_NAME = 'gitlab'
    GITLAB_SERVICE_ACCOUNT_NAMESPACE = 'default'
    GITLAB_ADMIN_TOKEN_NAME = 'gitlab-token'
    GITLAB_CLUSTER_ROLE_BINDING_NAME = 'gitlab-admin'
    GITLAB_CLUSTER_ROLE_NAME = 'cluster-admin'
    PROJECT_CLUSTER_ROLE_NAME = 'edit'
    GITLAB_KNATIVE_SERVING_ROLE_NAME = 'gitlab-knative-serving-role'
    GITLAB_KNATIVE_SERVING_ROLE_BINDING_NAME = 'gitlab-knative-serving-rolebinding'
    GITLAB_CROSSPLANE_DATABASE_ROLE_NAME = 'gitlab-crossplane-database-role'
    GITLAB_CROSSPLANE_DATABASE_ROLE_BINDING_NAME = 'gitlab-crossplane-database-rolebinding'
  end
end
