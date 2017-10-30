FactoryGirl.define do
  factory :cluster, class: Clusters::Cluster do
    user
    name 'test-cluster'
    provider_type :user
    platform_type :kubernetes

    trait :project do
      after(:create) do |cluster, evaluator|
        cluster.projects << create(:project)
      end
    end

    trait :provided_by_user do
      provider_type :user
      platform_type :kubernetes

      platform_kubernetes do
        create(:platform_kubernetes, :configured)
      end
    end

    trait :provided_by_gcp do
      provider_type :gcp
      platform_type :kubernetes

      platform_kubernetes do
        create(:platform_kubernetes, :configured)
      end

      provider_gcp do
        create(:provider_gcp, :created)
      end
    end

    trait :providing_by_gcp do
      provider_type :gcp
      platform_type :kubernetes

      provider_gcp do
        create(:provider_gcp, :creating)
      end

      after(:create) do |cluster, evaluator|
        create(:platform_kubernetes, cluster: cluster)
      end
    end
  end
end
