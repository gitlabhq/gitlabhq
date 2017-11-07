FactoryGirl.define do
  factory :cluster_applications_helm, class: Clusters::Applications::Helm do
    cluster factory: :cluster

    trait :installable do
      cluster
      status 0
    end

    trait :scheduled do
      cluster
      status 1
    end

    trait :installing do
      cluster
      status 2
    end

    trait :installed do
      cluster
      status 3
    end

    trait :errored do
      cluster
      status(-1)
      status_reason 'something went wrong'
    end

    trait :timeouted do
      installing
      updated_at ClusterWaitForAppInstallationWorker::TIMEOUT.ago
    end
  end
end
