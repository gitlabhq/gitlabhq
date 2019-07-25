# frozen_string_literal: true

FactoryBot.define do
  factory :import_state, class: ProjectImportState do
    status :none
    association :project, factory: :project

    transient do
      import_url { generate(:url) }
      import_type nil
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
      columns = {}
      columns[:import_url] = evaluator.import_url unless evaluator.import_url.blank?
      columns[:import_type] = evaluator.import_type unless evaluator.import_type.blank?

      import_state.project.update_columns(columns)
    end
  end
end
