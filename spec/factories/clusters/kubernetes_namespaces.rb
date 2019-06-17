# frozen_string_literal: true

FactoryBot.define do
  factory :cluster_kubernetes_namespace, class: Clusters::KubernetesNamespace do
    association :cluster, :project, :provided_by_gcp

    after(:build) do |kubernetes_namespace|
      if kubernetes_namespace.cluster.project_type?
        cluster_project = kubernetes_namespace.cluster.cluster_project

        kubernetes_namespace.project = cluster_project.project
        kubernetes_namespace.cluster_project = cluster_project
      end
    end

    trait :with_token do
      service_account_token { FFaker::Lorem.characters(10) }
    end

    trait :without_token do
      service_account_token nil
    end
  end
end
