# frozen_string_literal: true

FactoryBot.define do
  factory :deployment_cluster, class: 'DeploymentCluster' do
    cluster
    deployment
    kubernetes_namespace { 'the-namespace' }
  end
end
