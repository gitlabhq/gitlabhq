FactoryGirl.define do
  factory :cluster_applications_helm, class: Clusters::Applications::Helm do
    cluster factory: :cluster, strategy: :provided_by_gcp

    trait :installable do
      status :installable
    end

    trait :scheduled do
      status :scheduled
    end

    trait :installing do
      status :installing
    end

    trait :installed do
      status :installed
    end

    trait :errored do
      status :errored
      status_reason 'something went wrong'
    end

    trait :timeouted do
      installing
      updated_at ClusterWaitForAppInstallationWorker::TIMEOUT.ago
    end
  end
end
