# frozen_string_literal: true

FactoryBot.define do
  factory :cluster_kubernetes_namespace, class: 'Clusters::KubernetesNamespace' do
    association :cluster, :project, :provided_by_gcp

    after(:build) do |kubernetes_namespace|
      cluster = kubernetes_namespace.cluster

      if cluster.project_type?
        cluster_project = cluster.cluster_project

        kubernetes_namespace.project = cluster_project&.project
        kubernetes_namespace.cluster_project = cluster_project
      end

      if kubernetes_namespace.project
        kubernetes_namespace.namespace ||=
          Gitlab::Kubernetes::DefaultNamespace.new(
            cluster,
            project: kubernetes_namespace.project
          ).from_environment_slug(kubernetes_namespace.environment&.slug)
      end

      kubernetes_namespace.service_account_name ||= "#{kubernetes_namespace.namespace}-service-account"
    end

    trait :with_token do
      service_account_token { FFaker::Lorem.characters(10) }
    end

    trait :without_token do
      service_account_token { nil }
    end
  end
end
