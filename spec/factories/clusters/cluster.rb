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
      platform_kubernetes
    end

    trait :provided_by_gcp do
      provider_type :gcp
      platform_type :kubernetes
      platform_kubernetes

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
    end
  end
end
