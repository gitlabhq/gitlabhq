FactoryBot.define do
  factory :epic do
    title { generate(:title) }
    group
    author

    trait :use_fixed_dates do
      start_date { Date.new(2010, 1, 1) }
      start_date_fixed { Date.new(2010, 1, 1) }
      start_date_is_fixed true
      end_date { Date.new(2010, 1, 3) }
      due_date_fixed { Date.new(2010, 1, 3) }
      due_date_is_fixed true
    end

    factory :labeled_epic do
      transient do
        labels []
      end

      after(:create) do |epic, evaluator|
        epic.update(labels: evaluator.labels)
      end
    end
  end
end
