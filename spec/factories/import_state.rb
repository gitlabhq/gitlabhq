FactoryBot.define do
  factory :import_state, class: ProjectImportState do
    status :none
    association :project, factory: :project

    transient do
      import_url { generate(:url) }
    end

    trait :repository do
      association :project, factory: [:project, :repository]
    end

    trait :none do
      status :none
    end

    trait :scheduled do
      status :scheduled
    end

    trait :started do
      status :started
    end

    trait :finished do
      status :finished
    end

    trait :failed do
      status :failed
    end

    after(:create) do |import_state, evaluator|
      import_state.project.update_columns(import_url: evaluator.import_url)
    end
  end
end
