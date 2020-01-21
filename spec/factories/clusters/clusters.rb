# frozen_string_literal: true

FactoryBot.define do
  factory :cluster, class: 'Clusters::Cluster' do
    user
    name { 'test-cluster' }
    cluster_type { :project_type }
    managed { true }
    namespace_per_environment { true }

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

    trait :management_project do
      management_project factory: :project
    end

    trait :namespace_per_environment_disabled do
      namespace_per_environment { false }
    end

    trait :provided_by_user do
      provider_type { :user }
      platform_type { :kubernetes }

      platform_kubernetes factory: [:cluster_platform_kubernetes, :configured]
    end

    trait :provided_by_gcp do
      provider_type { :gcp }
      platform_type { :kubernetes }

      provider_gcp factory: [:cluster_provider_gcp, :created]
      platform_kubernetes factory: [:cluster_platform_kubernetes, :configured]
    end

    trait :provided_by_aws do
      provider_type { :aws }
      platform_type { :kubernetes }

      provider_aws factory: [:cluster_provider_aws, :created]
      platform_kubernetes factory: [:cluster_platform_kubernetes, :configured]
    end

    trait :providing_by_gcp do
      provider_type { :gcp }
      provider_gcp factory: [:cluster_provider_gcp, :creating]
    end

    trait :rbac_disabled do
      platform_kubernetes factory: [:cluster_platform_kubernetes, :configured, :rbac_disabled]
    end

    trait :cloud_run_enabled do
      provider_gcp factory: [:cluster_provider_gcp, :created, :cloud_run_enabled]
    end

    trait :disabled do
      enabled { false }
    end

    trait :production_environment do
      sequence(:environment_scope) { |n| "production#{n}/*" }
    end

    trait :with_installed_helm do
      application_helm factory: %i(clusters_applications_helm installed)
    end

    trait :with_domain do
      domain { 'example.com' }
    end

    trait :with_environments do
      transient do
        environments { %i(staging production) }
      end

      cluster_type { Clusters::Cluster.cluster_types[:project_type] }

      before(:create) do |cluster, evaluator|
        cluster_project = create(:cluster_project, cluster: cluster)

        evaluator.environments.each do |env_name|
          environment = create(:environment, name: env_name, project: cluster_project.project)

          cluster.kubernetes_namespaces << create(:cluster_kubernetes_namespace,
            cluster: cluster,
            cluster_project: cluster_project,
            project: cluster_project.project,
            environment: environment)
        end
      end
    end

    trait :not_managed do
      managed { false }
    end

    trait :cleanup_not_started do
      cleanup_status { 1 }
    end

    trait :cleanup_uninstalling_applications do
      cleanup_status { 2 }
    end

    trait :cleanup_removing_project_namespaces do
      cleanup_status { 3 }
    end

    trait :cleanup_removing_service_account do
      cleanup_status { 4 }
    end

    trait :cleanup_errored do
      cleanup_status { 5 }
    end
  end
end
