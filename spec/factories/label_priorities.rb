FactoryBot.define do
  factory :label_priority do
    project
    label
    sequence(:priority)
  end
end
