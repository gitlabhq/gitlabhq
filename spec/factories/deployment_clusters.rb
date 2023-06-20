# frozen_string_literal: true

FactoryBot.define do
  factory :deployment_cluster, class: 'DeploymentCluster' do
    cluster
    deployment
    kubernetes_namespace { 'the-namespace' }
  end

  trait :provided_by_gcp do
    cluster factory: %i[cluster provided_by_gcp]
  end

  trait :not_managed do
    cluster factory: %i[cluster not_managed]
  end
end
