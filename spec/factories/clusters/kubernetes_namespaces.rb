# frozen_string_literal: true

FactoryBot.define do
  factory :cluster_kubernetes_namespace, class: Clusters::KubernetesNamespace do
    cluster
    project
    cluster_project
  end
end
