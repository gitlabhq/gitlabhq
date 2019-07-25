# frozen_string_literal: true

FactoryBot.define do
  factory :cluster, class: Clusters::Cluster do
    user
    name 'test-cluster'
    cluster_type :project_type
    managed true

    factory :cluster_for_group, traits: [:provided_by_gcp, :group]

    trait :instance do
      cluster_type { Clusters::Cluster.cluster_types[:instance_type] }
    end

    trait :project do
      cluster_type { Clusters::Cluster.cluster_types[:project_type] }

      before(:create) do |cluster, evaluator|
        cluster.projects << create(:project) unless cluster.projects.present?
      end
    end

    trait :group do
      cluster_type { Clusters::Cluster.cluster_types[:group_type] }

      before(:create) do |cluster, evalutor|
        cluster.groups << create(:group) unless cluster.groups.present?
      end
    end

    trait :provided_by_user do
      provider_type :user
      platform_type :kubernetes

      platform_kubernetes factory: [:cluster_platform_kubernetes, :configured]
    end

    trait :provided_by_gcp do
      provider_type :gcp
      platform_type :kubernetes

      provider_gcp factory: [:cluster_provider_gcp, :created]
      platform_kubernetes factory: [:cluster_platform_kubernetes, :configured]
    end

    trait :providing_by_gcp do
      provider_type :gcp
      provider_gcp factory: [:cluster_provider_gcp, :creating]
    end

    trait :rbac_disabled do
      platform_kubernetes factory: [:cluster_platform_kubernetes, :configured, :rbac_disabled]
    end

    trait :disabled do
      enabled false
    end

    trait :production_environment do
      sequence(:environment_scope) { |n| "production#{n}/*" }
    end

    trait :with_installed_helm do
      application_helm factory: %i(clusters_applications_helm installed)
    end

    trait :with_domain do
      domain 'example.com'
    end

    trait :not_managed do
      managed false
    end
  end
end
