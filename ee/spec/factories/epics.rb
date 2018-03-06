FactoryBot.define do
  factory :epic do
    title { generate(:title) }
    group
    author

    factory :labeled_epic do
      transient do
        labels []
      end

      after(:create) do |epic, evaluator|
        epic.update_attributes(labels: evaluator.labels)
      end
    end
  end
end
