FactoryGirl.define do
  factory :applications_helm, class: Clusters::Applications::Helm do
    trait :cluster do
      before(:create) do |app, _|
        app.cluster = create(:cluster)
      end
    end

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
  end
end
